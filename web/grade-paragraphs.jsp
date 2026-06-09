<%@page import="myPackage.DatabaseClass"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Grade Paragraph Answers</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --primary-blue: #09294d;
            --secondary-blue: #1a3d6d;
            --accent-blue: #3b82f6;
            --white: #ffffff;
            --light-gray: #f8fafc;
            --border-color: #e2e8f0;
            --text-dark: #1e293b;
        }
        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--light-gray);
            color: var(--text-dark);
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            background: var(--white);
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            color: var(--primary-blue);
        }
        .back-btn {
            text-decoration: none;
            color: var(--primary-blue);
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .answer-card {
            background: var(--white);
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
            border-left: 5px solid var(--accent-blue);
        }
        .student-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid var(--border-color);
        }
        .student-name {
            font-size: 18px;
            font-weight: 700;
            color: var(--secondary-blue);
        }
        .submission-date {
            font-size: 14px;
            color: #64748b;
        }
        .question-box {
            background: #f1f5f9;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .question-label {
            font-weight: 700;
            color: var(--primary-blue);
            margin-bottom: 5px;
            display: block;
        }
        .student-answer {
            white-space: pre-wrap;
            background: #fff;
            padding: 15px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            min-height: 100px;
            margin-bottom: 25px;
            line-height: 1.6;
        }
        .grading-form {
            display: grid;
            grid-template-columns: 1fr 2fr auto;
            gap: 20px;
            align-items: start;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        label {
            font-weight: 600;
            font-size: 14px;
        }
        input[type="number"], textarea {
            padding: 12px;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            font-size: 14px;
        }
        button[type="submit"] {
            background: var(--primary-blue);
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
            align-self: end;
        }
        button[type="submit"]:hover {
            background: var(--secondary-blue);
        }
        .no-pending {
            text-align: center;
            padding: 50px;
            background: var(--white);
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        .alert {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .alert-success {
            background-color: #d1fae5;
            color: #065f46;
            border: 1px solid #a7f3d0;
        }
        .alert-error {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }
    </style>
</head>
<body>
    <div class="container">
        <%
            DatabaseClass pDAO = DatabaseClass.getInstance();
            String examIdStr = request.getParameter("examId");
            if (examIdStr == null || examIdStr.isEmpty()) {
        %>
            <div class="header">
                <h1>Select an Exam to Grade</h1>
                <a href="adm-page.jsp?pgprt=5" class="back-btn"><i class="fas fa-arrow-left"></i> Back to Results</a>
            </div>
            <div class="no-pending">
                <p>Please select an exam from the results page to grade paragraph answers.</p>
            </div>
        <%
            } else {
                int examId = Integer.parseInt(examIdStr);
                List<Map<String, Object>> pendingAnswers = pDAO.getPendingParagraphAnswers(examId);
        %>
            <div class="header">
                <h1>Grading: Exam #<%= examId %></h1>
                <a href="adm-page.jsp?pgprt=5" class="back-btn"><i class="fas fa-arrow-left"></i> Back to Results</a>
            </div>

            <% if (session.getAttribute("message") != null) { %>
                <div class="alert alert-success"><%= session.getAttribute("message") %></div>
                <% session.removeAttribute("message"); %>
            <% } %>
            <% if (session.getAttribute("error") != null) { %>
                <div class="alert alert-error"><%= session.getAttribute("error") %></div>
                <% session.removeAttribute("error"); %>
            <% } %>

            <% if (pendingAnswers.isEmpty()) { %>
                <div class="no-pending">
                    <i class="fas fa-check-circle" style="font-size: 48px; color: #10b981; margin-bottom: 20px;"></i>
                    <p>No pending paragraph answers for this exam.</p>
                    <a href="adm-page.jsp?pgprt=5" class="btn-primary" style="text-decoration:none; color:var(--accent-blue)">Return to Results</a>
                </div>
            <% } else { %>
                <% for (Map<String, Object> answer : pendingAnswers) { %>
                    <div class="answer-card">
                        <div class="student-info">
                            <div>
                                <div class="student-name"><%= answer.get("student_name") %></div>
                                <div style="font-size: 13px; color: #64748b;"><%= answer.get("student_email") %></div>
                            </div>
                            <div class="submission-date">
                                <i class="fas fa-calendar-alt"></i> Submitted: <%= answer.get("submitted_at") %>
                            </div>
                        </div>

                        <div class="question-box">
                            <span class="question-label">Question:</span>
                            <%= answer.get("question") %>
                        </div>

                        <span class="question-label">Student's Answer:</span>
                        <div class="student-answer"><%= answer.get("student_answer") %></div>

                        <form class="grading-form" method="post" action="controller.jsp">
                            <input type="hidden" name="page" value="grade_paragraph">
                            <input type="hidden" name="answerId" value="<%= answer.get("id") %>">
                            <input type="hidden" name="examId" value="<%= examId %>">

                            <div class="form-group">
                                <label>Marks (Max: <%= answer.get("max_marks") %>)</label>
                                <input type="number" name="marks" step="0.1" min="0" max="<%= answer.get("max_marks") %>" required placeholder="0.0">
                            </div>

                            <div class="form-group">
                                <label>Feedback (Optional)</label>
                                <textarea name="feedback" rows="2" placeholder="Provide feedback to the student..."></textarea>
                            </div>

                            <button type="submit"><i class="fas fa-save"></i> Save Grade</button>
                        </form>
                    </div>
                <% } %>
            <% } %>
        <% } %>
    </div>
</body>
</html>
