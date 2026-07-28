WITH sales AS (
  SELECT
    cc.cc_call_center_id,
    p.p_promo_name,
    d_sold.d_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  WHERE cc.cc_state = 'CA'
    AND p.p_channel_tv = 'Y'
    AND d_sold.d_year BETWEEN 1999 AND 2001
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 100.0
  GROUP BY cc.cc_call_center_id, p.p_promo_name, d_sold.d_year
),

returns AS (
  SELECT
    wp.wp_type,
    r.r_reason_desc,
    d_ret.d_year,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    AVG(wr.wr_return_quantity) AS avg_return_qty
  FROM web_returns wr
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  WHERE wp.wp_type = 'article'
    AND r.r_reason_desc LIKE '%product%'
    AND d_ret.d_year = 2000
    AND wr.wr_return_quantity > 1
    AND wr.wr_return_amt > 50.0
  GROUP BY wp.wp_type, r.r_reason_desc, d_ret.d_year
)

SELECT *
FROM (
  SELECT
    'sales' AS record_type,
    cc_call_center_id,
    p_promo_name,
    d_year,
    total_net_paid,
    sales_cnt,
    avg_discount,
    NULL AS wp_type,
    NULL AS r_reason_desc,
    NULL AS total_return_amt,
    NULL AS return_cnt,
    NULL AS avg_return_qty,
    SUM(total_net_paid) OVER (PARTITION BY d_year) AS yearly_sales_total,
    RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
  FROM sales
  UNION ALL
  SELECT
    'returns' AS record_type,
    NULL,
    NULL,
    d_year,
    NULL,
    NULL,
    NULL,
    wp_type,
    r_reason_desc,
    total_return_amt,
    return_cnt,
    avg_return_qty,
    SUM(total_return_amt) OVER (PARTITION BY d_year) AS yearly_return_total,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
  FROM returns
) combined
ORDER BY d_year DESC, record_type
LIMIT 100
