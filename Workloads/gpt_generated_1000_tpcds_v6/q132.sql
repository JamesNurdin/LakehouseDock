SELECT
    cc.cc_city,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_centers,
    MIN(d.d_date) AS earliest_open_date,
    MAX(d.d_date) AS latest_open_date
FROM call_center cc
JOIN date_dim d
    ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_moy = 6
  AND cc.cc_manager = 'Mark Hightower'
GROUP BY cc.cc_city
ORDER BY num_centers DESC, cc.cc_city
LIMIT 100
