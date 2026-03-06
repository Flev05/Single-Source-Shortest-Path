;; test_sssp.lisp - Tests for SSSP implementation (no external dependencies)
;; Uses a simple test runner with plain assertions.

;; Load the source file
(load "src/Lisp/sssp.lisp")


;; ----------------------------TEST FRAMEWORK-------------------------------

(defparameter *test-pass-count* 0)
(defparameter *test-fail-count* 0)
(defparameter *test-errors* nil)

(defun cleanup-test-state ()
  "Resets all global hash tables to a clean state."
  (clrhash *graphs*)
  (clrhash *vertices*)
  (clrhash *arcs*)
  (clrhash *visited*)
  (clrhash *distances*)
  (clrhash *previous*)
  (clrhash *heaps*))

(defmacro run-test (name &body body)
  "Runs a single test, catching errors and reporting results."
  `(progn
     (cleanup-test-state)
     (handler-case
         (progn ,@body
                (incf *test-pass-count*)
                (format t "  PASS: ~A~%" ,name))
       (error (e)
         (incf *test-fail-count*)
         (push (list ,name e) *test-errors*)
         (format t "  FAIL: ~A~%        ~A~%" ,name e)))))

(defmacro assert-true (expr &optional description)
  "Asserts that EXPR evaluates to a truthy value."
  `(unless ,expr
     (error "Assertion failed~@[: ~A~]~%  Expected truthy value from: ~S"
            ,description ',expr)))

(defmacro assert-false (expr &optional description)
  "Asserts that EXPR evaluates to NIL."
  `(when ,expr
     (error "Assertion failed~@[: ~A~]~%  Expected NIL from: ~S"
            ,description ',expr)))

(defmacro assert-equal (expected actual &optional description)
  "Asserts that EXPECTED and ACTUAL are EQUAL."
  (let ((e (gensym)) (a (gensym)))
    `(let ((,e ,expected) (,a ,actual))
       (unless (equal ,e ,a)
         (error "Assertion failed~@[: ~A~]~%  Expected: ~S~%  Actual:   ~S"
                ,description ,e ,a)))))

(defmacro assert-= (expected actual &optional description)
  "Asserts that EXPECTED and ACTUAL are numerically equal."
  (let ((e (gensym)) (a (gensym)))
    `(let ((,e ,expected) (,a ,actual))
       (unless (= ,e ,a)
         (error "Assertion failed~@[: ~A~]~%  Expected: ~S~%  Actual:   ~S"
                ,description ,e ,a)))))

(defun print-suite-header (name)
  (format t "~%=== ~A ===~%" name))

(defun print-summary ()
  (format t "~%========================================~%")
  (format t "Results: ~A passed, ~A failed~%"
          *test-pass-count* *test-fail-count*)
  (when *test-errors*
    (format t "~%Failed tests:~%")
    (dolist (err (reverse *test-errors*))
      (format t "  - ~A: ~A~%" (first err) (second err))))
  (format t "========================================~%"))


;; -------------------------GRAPH INTERFACE TESTS----------------------------

(defun run-graph-interface-tests ()
  (print-suite-header "Graph Interface Tests")

  (run-test "new-graph creates graph"
    (new-graph 'test)
    (assert-true (is-graph 'test)))

  (run-test "new-graph is idempotent"
    (new-graph 'test)
    (new-graph 'test)
    (let ((count 0))
      (maphash (lambda (k v)
                 (declare (ignore v))
                 (when (eq k 'test) (incf count)))
               *graphs*)
      (assert-= 1 count)))

  (run-test "new-vertex creates vertex"
    (new-graph 'g1)
    (new-vertex 'g1 'v1)
    (assert-true (member (list 'vertex 'g1 'v1)
                         (graph-vertices 'g1) :test #'equal)))

  (run-test "new-arc creates arc"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 5)
    (assert-true (member (list 'arc 'g1 'a 'b 5)
                         (graph-arcs 'g1) :test #'equal)))

  (run-test "new-arc default weight is 1"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b)
    (assert-true (member (list 'arc 'g1 'a 'b 1)
                         (graph-arcs 'g1) :test #'equal)))

  (run-test "new-arc updates existing arc"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 5)
    (new-arc 'g1 'a 'b 10)
    (assert-true (member (list 'arc 'g1 'a 'b 10)
                         (graph-arcs 'g1) :test #'equal))
    (assert-false (member (list 'arc 'g1 'a 'b 5)
                          (graph-arcs 'g1) :test #'equal)))

  (run-test "new-arc creates vertices automatically"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 5)
    (assert-true (member (list 'vertex 'g1 'a)
                         (graph-vertices 'g1) :test #'equal))
    (assert-true (member (list 'vertex 'g1 'b)
                         (graph-vertices 'g1) :test #'equal)))

  (run-test "graph-vertices returns all vertices"
    (new-graph 'g1)
    (new-vertex 'g1 'a)
    (new-vertex 'g1 'b)
    (new-vertex 'g1 'c)
    (let ((vs (mapcar #'third (graph-vertices 'g1))))
      (assert-true (subsetp '(a b c) vs))
      (assert-= 3 (length vs))))

  (run-test "graph-arcs returns all arcs"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 1)
    (new-arc 'g1 'b 'c 2)
    (assert-= 2 (length (graph-arcs 'g1))))

  (run-test "graph-vertex-neighbors returns outgoing arcs"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 1)
    (new-arc 'g1 'a 'c 2)
    (new-arc 'g1 'b 'c 3)
    (assert-= 2 (length (graph-vertex-neighbors 'g1 'a))))

  (run-test "delete-graph removes graph and its data"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 5)
    (delete-graph 'g1)
    (assert-false (is-graph 'g1))
    (assert-= 0 (length (graph-vertices 'g1)))
    (assert-= 0 (length (graph-arcs 'g1)))))


;; ---------------------------HEAP OPERATION TESTS--------------------------

(defun run-heap-operation-tests ()
  (print-suite-header "Heap Operation Tests")

  (run-test "new-heap creates heap"
    (new-heap 'test-heap)
    (assert-true (gethash 'test-heap *heaps*)))

  (run-test "heap-insert increases size"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 5 'v1)
    (assert-= 1 (heap-size (gethash 'test-heap *heaps*))))

  (run-test "heap-head returns minimum"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 10 'v1)
    (heap-insert 'test-heap 5 'v2)
    (let ((h (heap-head 'test-heap)))
      (assert-= 5 (first h))
      (assert-equal 'v2 (second h))))

  (run-test "heap-extract returns minimum"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 10 'v1)
    (heap-insert 'test-heap 5 'v2)
    (heap-insert 'test-heap 8 'v3)
    (let ((extracted (heap-extract 'test-heap)))
      (assert-= 5 (first extracted))
      (assert-equal 'v2 (second extracted))))

  (run-test "heap-extract removes element"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 5 'v1)
    (heap-extract 'test-heap)
    (assert-= 0 (heap-size (gethash 'test-heap *heaps*))))

  (run-test "heap-empty returns T for empty heap"
    (new-heap 'test-heap)
    (assert-true (heap-empty 'test-heap)))

  (run-test "heap-empty returns NIL for non-empty heap"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 5 'v1)
    (assert-false (heap-empty 'test-heap)))

  (run-test "heap-not-empty returns T for non-empty heap"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 5 'v1)
    (assert-true (heap-not-empty 'test-heap)))

  (run-test "heap-modify-key updates key"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 10 'v1)
    (heap-modify-key 'test-heap 3 10 'v1)
    (let ((h (heap-head 'test-heap)))
      (assert-= 3 (first h))))

  (run-test "heap-delete removes heap"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 5 'v1)
    (heap-delete 'test-heap)
    (assert-false (gethash 'test-heap *heaps*)))

  (run-test "heap extracts in sorted order"
    (new-heap 'test-heap)
    (heap-insert 'test-heap 7 'v1)
    (heap-insert 'test-heap 3 'v2)
    (heap-insert 'test-heap 9 'v3)
    (heap-insert 'test-heap 1 'v4)
    (heap-insert 'test-heap 5 'v5)
    (let ((r1 (first (heap-extract 'test-heap)))
          (r2 (first (heap-extract 'test-heap)))
          (r3 (first (heap-extract 'test-heap)))
          (r4 (first (heap-extract 'test-heap)))
          (r5 (first (heap-extract 'test-heap))))
      (assert-= 1 r1)
      (assert-= 3 r2)
      (assert-= 5 r3)
      (assert-= 7 r4)
      (assert-= 9 r5))))


;; --------------------------------SSSP TESTS-------------------------------

(defun run-sssp-tests ()
  (print-suite-header "SSSP Tests")

  (run-test "dijkstra computes correct distances"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 4)
    (new-arc 'g1 's 'b 2)
    (new-arc 'g1 'a 'b 1)
    (new-arc 'g1 'a 'c 5)
    (new-arc 'g1 'b 'c 8)
    (new-arc 'g1 'b 'd 10)
    (new-arc 'g1 'c 'd 2)
    (sssp-dijkstra 'g1 's)
    (assert-= 0 (sssp-dist 'g1 's))
    (assert-= 4 (sssp-dist 'g1 'a))
    (assert-= 2 (sssp-dist 'g1 'b))
    ;; c = min(s->a->c = 4+5, s->b->c = 2+8) = 9
    ;; d = min(s->b->d = 2+10, s->...->c->d = 9+2) = 11
    (assert-= 9 (sssp-dist 'g1 'c))
    (assert-= 11 (sssp-dist 'g1 'd)))

  (run-test "dijkstra marks source as visited"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 1)
    (sssp-dijkstra 'g1 's)
    (assert-true (sssp-visited 'g1 's)))

  (run-test "dijkstra marks all reachable vertices as visited"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 1)
    (new-arc 'g1 'a 'b 2)
    (sssp-dijkstra 'g1 's)
    (assert-true (sssp-visited 'g1 's))
    (assert-true (sssp-visited 'g1 'a))
    (assert-true (sssp-visited 'g1 'b)))

  (run-test "dijkstra sets previous correctly"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 4)
    (new-arc 'g1 's 'b 2)
    (new-arc 'g1 'a 'c 3)
    (new-arc 'g1 'b 'c 1)
    (sssp-dijkstra 'g1 's)
    ;; c via a: 4+3=7, c via b: 2+1=3. So previous of c is b.
    (assert-equal 'b (sssp-previous 'g1 'c)))

  (run-test "dijkstra source has distance 0"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 5)
    (sssp-dijkstra 'g1 's)
    (assert-= 0 (sssp-dist 'g1 's)))

  (run-test "dijkstra source has no previous"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 5)
    (sssp-dijkstra 'g1 's)
    (assert-false (sssp-previous 'g1 's))))


;; ---------------------------SHORTEST PATH TESTS---------------------------

(defun run-shortest-path-tests ()
  (print-suite-header "Shortest Path Tests")

  (run-test "shortest-path finds correct path"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 4)
    (new-arc 'g1 's 'b 2)
    (new-arc 'g1 'a 'c 3)
    (new-arc 'g1 'b 'c 1)
    (sssp-dijkstra 'g1 's)
    (let ((path (sssp-shortest-path 'g1 's 'c)))
      (assert-= 2 (length path))
      ;; Path should be s->b->c
      (assert-equal 's (third (first path)))
      (assert-equal 'b (fourth (first path)))
      (assert-equal 'b (third (second path)))
      (assert-equal 'c (fourth (second path)))))

  (run-test "shortest-path direct arc"
    (new-graph 'g1)
    (new-arc 'g1 's 't 5)
    (sssp-dijkstra 'g1 's)
    (let ((path (sssp-shortest-path 'g1 's 't)))
      (assert-= 1 (length path))
      (assert-= 5 (fifth (first path)))))

  (run-test "shortest-path source equals target returns empty"
    (new-graph 'g1)
    (new-arc 'g1 's 'a 1)
    (sssp-dijkstra 'g1 's)
    (let ((path (sssp-shortest-path 'g1 's 's)))
      (assert-true (null path))))

  (run-test "shortest-path multi-hop"
    (new-graph 'g1)
    (new-arc 'g1 'a 'b 1)
    (new-arc 'g1 'b 'c 2)
    (new-arc 'g1 'c 'd 3)
    (sssp-dijkstra 'g1 'a)
    (let ((path (sssp-shortest-path 'g1 'a 'd)))
      (assert-= 3 (length path))
      ;; Total weight: 1+2+3=6
      (assert-= 6 (sssp-dist 'g1 'd)))))


;; --------------------------------RUN ALL----------------------------------

(defun run-all-tests ()
  (setf *test-pass-count* 0)
  (setf *test-fail-count* 0)
  (setf *test-errors* nil)
  (format t "~%Running SSSP test suite...~%")
  (run-graph-interface-tests)
  (run-heap-operation-tests)
  (run-sssp-tests)
  (run-shortest-path-tests)
  (print-summary)
  ;; Exit with appropriate status code.
  ;; NOTE: sb-ext:exit is SBCL-specific. For other implementations,
  ;; replace with the corresponding exit function (e.g., ccl:quit,
  ;; ext:exit for CLISP, etc.)
  (if (> *test-fail-count* 0)
      (sb-ext:exit :code 1)
      (sb-ext:exit :code 0)))

(run-all-tests)
