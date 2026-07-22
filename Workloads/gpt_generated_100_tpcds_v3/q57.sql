SELECT
    d.d_date,
    cp.cp_department,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_name,
    t.t_shift,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cr.cr_return_amount,
    COUNT(DISTINCT p.p_promo_id) OVER (PARTITION BY cp.cp_department) AS distinct_promos_used,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    (SELECT SUM(wr.wr_return_amt)
     FROM web_returns wr
     WHERE wr.wr_returned_date_sk = d.d_date_sk) AS total_web_return_amount,
    CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND t.t_shift = 'first'
  AND p.p_discount_active = 'Y'
  AND cp.cp_department = 'Books'
  AND EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_returned_date_sk = d.d_date_sk)
ORDER BY profit_rank
LIMIT 100
