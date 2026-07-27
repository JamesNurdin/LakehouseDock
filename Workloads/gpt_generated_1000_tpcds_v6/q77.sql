SELECT
    d.d_year,
    hd.hd_buy_potential,
    CASE WHEN ss.ss_net_paid > 100 THEN 'High' ELSE 'Low' END AS sales_category,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    MIN(ss.ss_net_paid) AS min_net_paid,
    MAX(ss.ss_net_paid) AS max_net_paid
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2002
  AND d.d_date_id = 'AAAAAAAABLJNECAA'
  AND hd.hd_buy_potential = '501-1000'
  AND ss.ss_quantity > 1
  AND ss.ss_list_price > 50
GROUP BY d.d_year,
         hd.hd_buy_potential,
         CASE WHEN ss.ss_net_paid > 100 THEN 'High' ELSE 'Low' END
ORDER BY d.d_year DESC,
         total_net_paid DESC
LIMIT 100
