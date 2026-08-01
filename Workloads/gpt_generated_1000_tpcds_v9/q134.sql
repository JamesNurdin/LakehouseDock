SELECT
    d.d_year,
    CONCAT(i.i_brand, ' ', i.i_class) AS brand_class,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)', 1) AS reason_word,
    SUBSTRING(r.r_reason_desc FROM 1 FOR 10) AS reason_prefix,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(wr.wr_net_loss) AS avg_net_loss
FROM web_returns wr
JOIN web_sales ws
  ON wr.wr_order_number = ws.ws_order_number
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE i.i_item_desc LIKE '%PROMO%'
  AND REGEXP_LIKE(r.r_reason_desc, '(?i)damaged|broken|defective')
  AND wsit.web_name LIKE '%Online%'
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    i.i_brand,
    i.i_class,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)', 1),
    SUBSTRING(r.r_reason_desc FROM 1 FOR 10)
HAVING SUM(wr.wr_return_amt_inc_tax) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
