WITH
sales_agg AS (
  SELECT
    cs.cs_call_center_sk AS cc_call_center_sk,
    d.d_year,
    d.d_month_seq,
    d.d_moy,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS cnt_sales,
    AVG(cs.cs_quantity) AS avg_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE (cc.cc_closed_date_sk IS NULL OR cc.cc_closed_date_sk > d.d_date_sk)
    AND cc.cc_gmt_offset IS NOT NULL
  GROUP BY cs.cs_call_center_sk, d.d_year, d.d_month_seq, d.d_moy
),
returns_agg AS (
  SELECT
    cr.cr_call_center_sk AS cc_call_center_sk,
    d.d_year,
    d.d_month_seq,
    d.d_moy,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS cnt_returns,
    AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE (cc.cc_division = 1 OR cc.cc_division IS NULL)
  GROUP BY cr.cr_call_center_sk, d.d_year, d.d_month_seq, d.d_moy
),
joined AS (
  SELECT
    COALESCE(s.cc_call_center_sk, r.cc_call_center_sk) AS cc_call_center_sk,
    COALESCE(s.d_year, r.d_year) AS d_year,
    COALESCE(s.d_month_seq, r.d_month_seq) AS d_month_seq,
    COALESCE(s.d_moy, r.d_moy) AS d_moy,
    s.total_net_profit,
    r.total_net_loss,
    s.total_discount,
    r.total_return_amount,
    s.cnt_sales,
    r.cnt_returns,
    (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_profit_adj,
    (COALESCE(s.total_discount, 0) / NULLIF(COALESCE(r.total_return_amount, 0), 0)) AS discount_return_ratio,
    concat_ws(' ', cc.cc_name, cc.cc_city, COALESCE(cc.cc_state, 'UNKNOWN')) AS call_center_desc
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.cc_call_center_sk IS NOT DISTINCT FROM r.cc_call_center_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
  LEFT JOIN call_center cc
    ON COALESCE(s.cc_call_center_sk, r.cc_call_center_sk) = cc.cc_call_center_sk
),
ranked AS (
  SELECT
    *,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit_adj DESC NULLS LAST) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit_adj DESC NULLS LAST) AS yearly_rownum
  FROM joined
),
final_result AS (
  SELECT
    rk.cc_call_center_sk,
    cc.cc_name,
    rk.d_year,
    rk.d_moy,
    rk.net_profit_adj,
    rk.profit_rank,
    CASE
      WHEN rk.net_profit_adj IS NULL THEN 'No Data'
      WHEN rk.net_profit_adj < 0 THEN 'Loss'
      ELSE 'Profit'
    END AS profit_status,
    CASE WHEN rk.profit_rank <= 3 THEN 1 ELSE 0 END AS top3_flag,
    rk.discount_return_ratio,
    (
      SELECT i.i_product_name
      FROM catalog_sales cs2
      JOIN item i ON cs2.cs_item_sk = i.i_item_sk
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE cs2.cs_call_center_sk = rk.cc_call_center_sk
        AND d2.d_year = rk.d_year
        AND d2.d_month_seq = rk.d_month_seq
      GROUP BY i.i_product_name
      ORDER BY SUM(cs2.cs_quantity) DESC
      LIMIT 1
    ) AS top_item
  FROM ranked rk
  LEFT JOIN call_center cc ON rk.cc_call_center_sk = cc.cc_call_center_sk
  WHERE (rk.net_profit_adj IS NULL OR rk.net_profit_adj >= 0 OR (rk.profit_rank IS NOT NULL AND rk.profit_rank <= 3))
)
SELECT
  cc_call_center_sk,
  cc_name,
  d_year,
  d_moy,
  net_profit_adj,
  profit_rank,
  profit_status,
  top3_flag,
  discount_return_ratio,
  top_item
FROM final_result
UNION ALL
SELECT
  cc.cc_call_center_sk,
  cc.cc_name,
  d.d_year,
  d.d_moy,
  CAST(0.0 AS decimal(7,2)) AS net_profit_adj,
  CAST(NULL AS BIGINT) AS profit_rank,
  'No Sales/Returns' AS profit_status,
  0 AS top3_flag,
  CAST(NULL AS decimal(15,5)) AS discount_return_ratio,
  CAST(NULL AS varchar) AS top_item
FROM call_center cc
CROSS JOIN (SELECT DISTINCT d_year, d_moy FROM date_dim) d
WHERE NOT EXISTS (
  SELECT 1
  FROM final_result fr
  WHERE fr.cc_call_center_sk = cc.cc_call_center_sk
    AND fr.d_year = d.d_year
    AND fr.d_moy = d.d_moy
)
ORDER BY d_year, d_moy, net_profit_adj DESC NULLS LAST
