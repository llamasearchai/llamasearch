"""PDF processing utilities for Research Code Automation Tool."""

import os
import logging
import tempfile
import asyncio
import subprocess
from typing import Union, BinaryIO, Dict, Any, Optional, List
import PyPDF2
from research_code_automation.config import settings

logger = logging.getLogger(__name__)

class PDFProcessor:
    """Processor for extracting text from PDFs with OCR capabilities."""
    
    def __init__(self):
        """Initialize the PDF processor."""
        self.ocrmypdf_available = self._check_ocrmypdf()
        self.pytesseract_available = self._check_pytesseract()
        
        if not self.ocrmypdf_available and not self.pytesseract_available:
            logger.warning("Neither OCRmyPDF nor PyTesseract are available. OCR will be disabled.")
    
    def _check_ocrmypdf(self) -> bool:
        """Check if OCRmyPDF is available."""
        try:
            subprocess.run(["ocrmypdf", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            logger.warning("OCRmyPDF not found. Install it with 'apt-get install ocrmypdf' or pip.")
            return False
    
    def _check_pytesseract(self) -> bool:
        """Check if PyTesseract is available."""
        try:
            import pytesseract
            pytesseract.get_tesseract_version()
            return True
        except (ImportError, Exception):
            logger.warning("PyTesseract not found or Tesseract not installed. Install both for OCR functionality.")
            return False
    
    async def extract_text(
        self, 
        pdf_file: Union[str, BinaryIO], 
        ocr_enabled: bool = False,
        language: str = "eng",
    ) -> str:
        """
        Extract text from a PDF file.
        
        Args:
            pdf_file: Path to PDF file or file-like object
            ocr_enabled: Whether to use OCR
            language: Language code for OCR (ISO 639-2/T format)
            
        Returns:
            Extracted text from the PDF
        """
        if ocr_enabled and not (self.ocrmypdf_available or self.pytesseract_available):
            logger.warning("OCR requested but OCR tools not available. Falling back to regular extraction.")
            ocr_enabled = False
        
        # Handle file-like objects
        if not isinstance(pdf_file, str):
            with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as temp:
                temp.write(pdf_file.read() if hasattr(pdf_file, 'read') else pdf_file)
                temp_path = temp.name
            
            try:
                return await self._process_pdf(temp_path, ocr_enabled, language)
            finally:
                # Clean up the temporary file
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
        else:
            # Direct path provided
            return await self._process_pdf(pdf_file, ocr_enabled, language)
    
    async def _process_pdf(self, pdf_path: str, ocr_enabled: bool, language: str) -> str:
        """
        Process a PDF file and extract text.
        
        Args:
            pdf_path: Path to the PDF file
            ocr_enabled: Whether to use OCR
            language: Language code for OCR
            
        Returns:
            Extracted text
        """
        if ocr_enabled:
            # Try OCRmyPDF first if available
            if self.ocrmypdf_available:
                try:
                    return await self._extract_with_ocrmypdf(pdf_path, language)
                except Exception as e:
                    logger.error(f"Error using OCRmyPDF: {str(e)}. Falling back to PyTesseract.")
            
            # Fall back to PyTesseract
            if self.pytesseract_available:
                try:
                    return await self._extract_with_pytesseract(pdf_path, language)
                except Exception as e:
                    logger.error(f"Error using PyTesseract: {str(e)}. Falling back to regular extraction.")
        
        # Regular extraction without OCR
        return await self._extract_without_ocr(pdf_path)
    
    async def _extract_with_ocrmypdf(self, pdf_path: str, language: str) -> str:
        """
        Extract text using OCRmyPDF.
        
        Args:
            pdf_path: Path to the PDF file
            language: Language code for OCR
            
        Returns:
            Extracted text
        """
        output_path = tempfile.mktemp(suffix=".pdf")
        
        try:
            # Run OCRmyPDF
            process = await asyncio.create_subprocess_exec(
                "ocrmypdf",
                "--force-ocr",
                "--skip-text",
                f"--language={language}",
                pdf_path,
                output_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                logger.error(f"OCRmyPDF failed: {stderr.decode()}")
                raise RuntimeError(f"OCRmyPDF failed with code {process.returncode}")
            
            # Extract text from the OCR'd PDF
            return await self._extract_without_ocr(output_path)
            
        finally:
            # Clean up the temporary file
            if os.path.exists(output_path):
                os.unlink(output_path)
    
    async def _extract_with_pytesseract(self, pdf_path: str, language: str) -> str:
        """
        Extract text using PyTesseract.
        
        Args:
            pdf_path: Path to the PDF file
            language: Language code for OCR
            
        Returns:
            Extracted text
        """
        import pytesseract
        from PIL import Image
        import fitz  # PyMuPDF
        
        doc = fitz.open(pdf_path)
        text_parts = []
        
        # Function to process a single page in a separate process
        async def process_page(page):
            pix = page.get_pixmap(matrix=fitz.Matrix(300/72, 300/72))
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            text = pytesseract.image_to_string(img, lang=language)
            return text
        
        # Process pages concurrently
        tasks = [process_page(doc[page_num]) for page_num in range(len(doc))]
        results = await asyncio.gather(*tasks)
        
        doc.close()
        return "\n\n".join(results)
    
    async def _extract_without_ocr(self, pdf_path: str) -> str:
        """
        Extract text from PDF without using OCR.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            Extracted text
        """
        def extract_text_from_pdf():
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                text = ""
                for page_num in range(len(pdf_reader.pages)):
                    page = pdf_reader.pages[page_num]
                    text += page.extract_text() + "\n\n"
                return text
        
        # Run in a thread to avoid blocking the event loop
        loop = asyncio.get_event_loop()
        text = await loop.run_in_executor(None, extract_text_from_pdf)
        
        if not text.strip():
            logger.warning(f"No text extracted from {pdf_path}. The PDF might be scanned or contain only images.")
        
        return text
    
    async def get_pdf_metadata(self, pdf_path: str) -> Dict[str, Any]:
        """
        Extract metadata from a PDF file.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            Dictionary of metadata
        """
        def extract_metadata():
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                metadata = pdf_reader.metadata
                num_pages = len(pdf_reader.pages)
                
                result = {
                    "title": metadata.get("/Title", None),
                    "author": metadata.get("/Author", None),
                    "subject": metadata.get("/Subject", None),
                    "creator": metadata.get("/Creator", None),
                    "producer": metadata.get("/Producer", None),
                    "creation_date": str(metadata.get("/CreationDate", None)),
                    "modification_date": str(metadata.get("/ModDate", None)),
                    "num_pages": num_pages,
                }
                
                return result
        
        # Run in a thread to avoid blocking the event loop
        loop = asyncio.get_event_loop()
        metadata = await loop.run_in_executor(None, extract_metadata)
        
        return metadata 