WITH cr_full AS (
  -- Full outer join between returns and reason, then enrich with date dimension
  SELECT 
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    r.r_reason_desc,
    d.d_year,
    d.d_quarter_seq
  FROM catalog_returns cr
  FULL OUTER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
),
ws_full AS (
  -- Sampled web sales enriched with date, site and customer demographics
  SELECT 
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    d.d_year AS ws_year,
    d.d_quarter_seq AS ws_quarter_seq,
    ws_site.web_name,
    ws_site.web_state,
    ws_site.web_gmt_offset,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender
  FROM (
        SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
      ) ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
),
cr_agg AS (
  -- Aggregate returns per year and reason
  SELECT 
    d_year,
    r_reason_desc,
    SUM(cr_return_amount) AS sum_return_amount,
    SUM(cr_net_loss)      AS sum_net_loss,
    COUNT(*)              AS cnt_returns
  FROM cr_full
  WHERE r_reason_desc IS NOT NULL
    AND d_year BETWEEN 1999 AND 2001
  GROUP BY d_year, r_reason_desc
),
ws_agg AS (
  -- Aggregate sales per year, site and state, expanding an array with UNNEST
  SELECT 
    ws_year,
    web_name,
    web_state,
    SUM(ws_ext_sales_price) AS sum_sales,
    SUM(ws_net_profit)      AS sum_profit,
    COUNT(*)                AS cnt_sales,
    state_or_name
  FROM ws_full
  CROSS JOIN UNNEST(ARRAY[web_state, web_name]) AS t(state_or_name)
  WHERE web_state IN ('SC', 'CO', 'TN')
    AND ws_ext_sales_price > 1000
    AND ws_year BETWEEN 1999 AND 2001
  GROUP BY ws_year, web_name, web_state, state_or_name
  HAVING SUM(ws_ext_sales_price) > 5000
),
final AS (
  -- Combine the two aggregated results (star topology) via CROSS JOIN
  SELECT 
    cr.d_year               AS return_year,
    cr.r_reason_desc,
    ws.ws_year              AS sales_year,
    ws.web_name,
    ws.web_state,
    cr.sum_return_amount,
    ws.sum_sales,
    cr.sum_net_loss,
    ws.sum_profit,
    cr.cnt_returns,
    ws.cnt_sales,
    ws.state_or_name
  FROM cr_agg cr
  CROSS JOIN ws_agg ws
)
SELECT *
FROM final
ORDER BY sum_sales DESC
LIMIT 100
