-- SQL Table for Paragraph/Short Answer Submissions
-- Stores student responses to PARAGRAPH-type questions that require manual marking
-- These answers are stored in the answers table with question_type stored in questions table

CREATE TABLE IF NOT EXISTS `paragraph_answers` (
  `answer_id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `std_id` varchar(45) NOT NULL,
  `student_answer` longtext NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT NULL,
  `feedback` longtext DEFAULT NULL,
  `marked_by` varchar(45) DEFAULT NULL,
  `marked_date` datetime DEFAULT NULL,
  `submitted_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(20) DEFAULT 'PENDING',
  PRIMARY KEY (`answer_id`),
  FOREIGN KEY (`exam_id`) REFERENCES `exams`(`exam_id`) ON DELETE CASCADE,
  FOREIGN KEY (`question_id`) REFERENCES `questions`(`question_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Index for faster queries
CREATE INDEX idx_exam_paragraph_answers ON paragraph_answers(exam_id);
CREATE INDEX idx_question_paragraph_answers ON paragraph_answers(question_id);
CREATE INDEX idx_status_paragraph_answers ON paragraph_answers(status);
CREATE INDEX idx_std_paragraph_answers ON paragraph_answers(std_id);

-- Update the question_type enum to include PARAGRAPH if not already present
-- Run this ALTER TABLE command in phpMyAdmin directly if PARAGRAPH is not in the enum options:
-- ALTER TABLE `questions` MODIFY COLUMN `question_type` enum('MCQ', 'TrueFalse', 'MultipleSelect', 'Code', 'DRAG_AND_DROP', 'REARRANGE', 'PARAGRAPH') DEFAULT 'MCQ';
