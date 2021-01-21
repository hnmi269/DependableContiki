### Hi there 👋

Dependable Contiki

This long-term goal of this project is to develop a dependable version of the Contiki operating system, which is an operating system for low-end IoT devices. We have currently focused on the most critical component of Contiki, which is its scheduler. Specifically, we have analyzed the source code of Contiki's scheduler (in process.c file) and have extracted a formal model of the scheduler in Promela. Using the SPIN model checker, we have verified some critical properties of the scheduler. To the best of our knowledge, this is the first comprehensive formal specification and verification of Contiki's scheduler. Our verification attempt has resulted in finding some subtle design flaws in the scheduler (for the first time).
