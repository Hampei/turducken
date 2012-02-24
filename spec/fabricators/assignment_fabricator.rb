Fabricator(:assignment, class_name: 'turducken/assignment') do
  assignment_id {"32A8TDZQEZYRV8#{sequence(:turk_id, 1111)}"}
  answers {{'tweet' => 'this a legal tweet.'}}
  feedback nil
  job {Fabricate(:job)}
  worker {Fabricate(:worker)}
  assignment_result_type nil
  assignment_result_id nil
end
