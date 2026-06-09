<%@page import="java.sql.*"%>
<%@page import="java.io.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Setup Paragraph Table</title>
</head>
<body>
    <h1>Database Setup for Paragraph Questions</h1>
    <%
    Connection conn = null;
    Statement stmt = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/exam_system", "root", "");
        stmt = conn.createStatement();

        // 1. Create paragraph_answers table
        String createTableSql = "CREATE TABLE IF NOT EXISTS paragraph_answers ( " +
                                "id INT PRIMARY KEY AUTO_INCREMENT, " +
                                "exam_id INT NOT NULL, " +
                                "question_id INT NOT NULL, " +
                                "student_id INT NOT NULL, " +
                                "question TEXT, " +
                                "student_answer TEXT, " +
                                "marks_obtained FLOAT DEFAULT 0, " +
                                "max_marks FLOAT DEFAULT 0, " +
                                "status ENUM('pending', 'graded', 'skipped') DEFAULT 'pending', " +
                                "feedback TEXT, " +
                                "submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                                "graded_at TIMESTAMP NULL, " +
                                "INDEX idx_exam (exam_id), " +
                                "INDEX idx_student (student_id), " +
                                "INDEX idx_status (status), " +
                                "FOREIGN KEY (exam_id) REFERENCES exams(exam_id) ON DELETE CASCADE, " +
                                "FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE " +
                                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";

        try {
            stmt.execute(createTableSql);
            out.println("<p style='color:green'>✓ Table 'paragraph_answers' created or already exists.</p>");
        } catch (SQLException e) {
            out.println("<p style='color:red'>✗ Error creating table: " + e.getMessage() + "</p>");
        }

        // 2. Update questions.question_type ENUM
        String alterQuestionsSql = "ALTER TABLE questions MODIFY COLUMN question_type ENUM('MCQ', 'TrueFalse', 'MultipleSelect', 'Code', 'DRAG_AND_DROP', 'REARRANGE', 'PARAGRAPH') DEFAULT 'MCQ'";
        try {
            stmt.execute(alterQuestionsSql);
            out.println("<p style='color:green'>✓ Updated 'questions.question_type' enum.</p>");
        } catch (SQLException e) {
            out.println("<p style='color:blue'>○ Note (Questions table update): " + e.getMessage() + "</p>");
        }

        out.println("<h2>Setup Complete</h2>");

    } catch (Exception e) {
        out.println("<p style='color:red'>Error: " + e.getMessage() + "</p>");
        e.printStackTrace(new PrintWriter(out));
    } finally {
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
    %>
</body>
</html>
