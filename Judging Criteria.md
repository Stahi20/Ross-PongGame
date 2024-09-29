Creativity:
We approached this project with a creative mindset, designing a Pong-style game using SystemVerilog for video output. By incorporating dynamic elements like moving paddles, a bouncing ball, and score tracking, we added an engaging twist to video processing. The feature of changing ball colors upon scoring showcases our ability to blend game design with hardware description language (HDL) in a unique way.

Learning Process:
We learned a lot about YCbCr422 color formats and how video data is represented, which we applied through the color palette array and transitions for the game objects like the ball. Understanding video signal transmission and timing signals (e.g., fvht_i, vdat_bars_i) was key to our progress. As a team, we documented our learning process, including experimenting with video generation and testing edge detection, making sure we captured each step of our journey.

Code Quality:
We ensured that our code is clean and well-structured, with clear comments and modular organization. The game logic for paddle and ball movements, video signal processing, and timing signals were handled systematically, making the code readable and maintainable. Functions like is_in_paddle(), is_in_ball(), and is_in_digit() were written to improve reusability and clarity.

Use of SystemVerilog Features:
While we primarily utilized basic SystemVerilog features like always blocks, register declarations, and functions, we could have further explored advanced features such as interfaces or object-oriented design. Our focus was on achieving reliable execution and clarity, but expanding these aspects could add more depth and modularity to our design.

Design Choices:
We made deliberate design choices throughout the project. By using parameters for paddle and ball positions, we ensured flexibility and easy adjustments. The straightforward approach to scorekeeping and ball color updates provided an engaging player experience. Using pixel counters (x_counter, y_counter) and edge detection logic for video synchronization allowed us to maintain efficient video output with accurate timing. We made trade-offs to balance simplicity with real-time performance.

Articulation of Constraints:
We had to work within several constraints, such as the screen resolution (1920x1125), timing requirements (vertical and horizontal sync), and the need for real-time performance. We made careful trade-offs between hardware resource usage and functionality, keeping paddle movements smooth and ensuring that video output happened seamlessly in real-time.

Efficiency & Optimization:
Our design is fairly efficient given that it outputs real-time video, but there is room for optimization. We could reduce hardware resource usage, for example, by minimizing register sizes for ball and paddle positions. Additionally, we focused on maintaining accurate timing and synchronization, and there are opportunities to further optimize performance.

Robustness:
Our design is reliable for handling basic video output and game mechanics. However, we could enhance robustness by better managing edge cases, such as handling faster ball speeds or overlapping paddles. Adding these safeguards would improve performance across a wider range of conditions, ensuring smooth gameplay and display output.

Team Collaboration:
We worked well together as a team, dividing tasks based on our strengths. One team member focused on game logic, while the other handled video output, color formatting, and timing signals. By maintaining clear communication and documenting our progress, we were able to integrate our contributions smoothly. The clear comments in our code reflect our collaborative effort.

Presentation and Communication:
In our presentation, we would explain how we implemented the game logic, including how the paddles, ball, and scoring are controlled in hardware. We would also cover the color format and how it was applied to the ball and background. By sharing the challenges we faced—such as syncing game updates with video output—and explaining the trade-offs we made, we would demonstrate how we balanced complexity with functionality.

Summary
Our Pong-style game design using SystemVerilog highlights creativity and a deep understanding of video processing. We ensured the code is well-structured and clean, though there is potential for further exploration of advanced SystemVerilog features and optimizations. Our presentation will focus on the learning process, design decisions, and key trade-offs we made to create a fun and functional project.
