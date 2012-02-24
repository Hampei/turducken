Fabricator(:worker) do
  turk_id {"A14F31B#{sequence(:turk_id, 1111)}"}
  sex 'Male'
end
