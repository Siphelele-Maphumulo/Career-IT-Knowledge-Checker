-- Migration script to fix questions table schema for Paragraph questions and consistency
-- Synchronized with the exact schema provided by the user

-- 1. Ensure core columns exist and have correct types
ALTER TABLE `questions`
MODIFY COLUMN `course_name` VARCHAR(100) NOT NULL,
MODIFY COLUMN `question` LONGTEXT NOT NULL,
MODIFY COLUMN `opt1` TEXT DEFAULT NULL,
MODIFY COLUMN `opt2` LONGTEXT NOT NULL,
MODIFY COLUMN `opt3` LONGTEXT DEFAULT NULL,
MODIFY COLUMN `opt4` LONGTEXT DEFAULT NULL,
MODIFY COLUMN `correct` TEXT DEFAULT NULL;

-- 2. Add/Modify enhancement columns
-- Note: Using multiple ALTER TABLE statements or comma-separated if supported.
-- 'marks' as DECIMAL(5,2)
ALTER TABLE `questions`
ADD COLUMN IF NOT EXISTS `image_path` VARCHAR(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `extra_data` TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `marks` DECIMAL(5,2) DEFAULT 1.00,
ADD COLUMN IF NOT EXISTS `question_type` ENUM('MCQ','TrueFalse','MultipleSelect','Code','DRAG_AND_DROP','REARRANGE','PARAGRAPH') DEFAULT 'MCQ';

-- 3. Ensure columns have correct definitions if they already existed
ALTER TABLE `questions`
MODIFY COLUMN `marks` DECIMAL(5,2) DEFAULT 1.00,
MODIFY COLUMN `question_type` ENUM('MCQ','TrueFalse','MultipleSelect','Code','DRAG_AND_DROP','REARRANGE','PARAGRAPH') DEFAULT 'MCQ';

-- 4. Add Drag and Drop specific columns if missing
ALTER TABLE `questions`
ADD COLUMN IF NOT EXISTS `drag_items` TEXT NULL,
ADD COLUMN IF NOT EXISTS `drop_targets` TEXT NULL,
ADD COLUMN IF NOT EXISTS `drag_correct_targets` TEXT NULL;

-- 5. Final pass for defaults
UPDATE `questions` SET `question_type` = 'MCQ' WHERE `question_type` IS NULL;
UPDATE `questions` SET `marks` = 1.00 WHERE `marks` IS NULL;

-- Verify columns
DESCRIBE `questions`;
