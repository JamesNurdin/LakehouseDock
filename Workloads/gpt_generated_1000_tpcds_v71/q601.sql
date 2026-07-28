SELECT DISTINCT sm_ship_mode_id,
                sm_type
FROM   ship_mode
WHERE  sm_contract IN ('GNJr3g5i7oorKqtX', '2mM8l')
  AND  sm_code = 'AIR'
LIMIT 100
