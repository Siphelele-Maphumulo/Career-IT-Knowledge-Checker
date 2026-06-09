<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="myPackage.DatabaseClass"%>
<%@page import="myPackage.classes.Questions"%>
<%@page import="org.json.JSONObject"%>
<!DOCTYPE html>
<html>
<head>
    <title>Verification Fix</title>
</head>
<body>
    <h1>Verifying Paragraph Question Fix</h1>
    <%
        try {
            DatabaseClass pDAO = DatabaseClass.getInstance();

            // 1. Check schema
            out.println("<h2>Step 1: Schema Verification</h2>");
            try {
                // Testing if column exists by attempting to select it
                pDAO.getPreparedStatement("SELECT marks, extra_data FROM questions LIMIT 1").executeQuery().close();
                out.println("<p style='color:green'>SUCCESS: 'marks' and 'extra_data' columns found.</p>");
            } catch (Exception e) {
                out.println("<p style='color:red'>FAILURE: Missing columns. Error: " + e.getMessage() + "</p>");
            }

            // 2. Test Insert
            out.println("<h2>Step 2: Insertion Test</h2>");
            String testCourse = "FixVerificationCourse_" + System.currentTimeMillis();
            String extraData = "{\"minWords\": \"50\", \"maxWords\": \"500\"}";
            int marks = 10;

            int qid = pDAO.addNewQuestionReturnId(
                "Test Paragraph Question?",
                "", "", "", "", "",
                testCourse,
                "PARAGRAPH",
                null,
                extraData,
                marks
            );

            if (qid > 0) {
                out.println("<p style='color:green'>SUCCESS: Paragraph question inserted with ID: " + qid + "</p>");

                // 3. Test Retrieval
                out.println("<h2>Step 3: Retrieval Test</h2>");
                Questions q = pDAO.getQuestionById(qid);
                if (q != null) {
                    out.println("<ul>");
                    out.println("<li>Question: " + q.getQuestion() + "</li>");
                    out.println("<li>Type: " + q.getQuestionType() + "</li>");
                    out.println("<li>Marks (TotalMarks in Obj): " + q.getTotalMarks() + "</li>");
                    out.println("<li>Extra Data: " + q.getExtraData() + "</li>");
                    out.println("</ul>");

                    if (Math.abs(q.getTotalMarks() - (float)marks) < 0.001 && extraData.equals(q.getExtraData())) {
                        out.println("<p style='color:green'>SUCCESS: Data retrieved matches data inserted.</p>");
                    } else {
                        out.println("<p style='color:red'>FAILURE: Data mismatch. Expected marks: " + marks + ", Found: " + q.getTotalMarks() + "</p>");
                    }
                } else {
                    out.println("<p style='color:red'>FAILURE: Could not retrieve question after insert.</p>");
                }

                // Cleanup
                pDAO.deleteQuestion(qid);
                pDAO.delCourse(testCourse);
            } else {
                out.println("<p style='color:red'>FAILURE: Insertion failed.</p>");
            }

        } catch (Exception e) {
            out.println("<p style='color:red'>UNEXPECTED ERROR: " + e.getMessage() + "</p>");
            e.printStackTrace(new java.io.PrintWriter(out));
        }
    %>
</body>
</html>
