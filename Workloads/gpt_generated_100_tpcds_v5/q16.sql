WITH web_agg AS (
    SELECT d.d_moy AS month,
           'WebReturn' AS source,
           SUM(wr.wr_net_loss) AS total_amount,
           CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_moy IN (1, 7, 12)
    GROUP BY d.d_moy
),
call_agg AS (
    SELECT d.d_moy AS month,
           'CallCenter' AS source,
           CAST(COUNT(cc.cc_call_center_sk) AS decimal(15,2)) AS total_amount,
           CASE WHEN AVG(cc.cc_tax_percentage) > 5.00 THEN 'HighTax' ELSE 'LowTax' END AS loss_category
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_division = 3
    GROUP BY d.d_moy
)
SELECT month,
       source,
       total_amount,
       loss_category
FROM web_agg
UNION ALL
SELECT month,
       source,
       total_amount,
       loss_category
FROM call_agg
ORDER BY month, source
LIMIT 100
