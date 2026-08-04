WITH
  -- a single date row to be used in a CROSS JOIN
  single_date AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_date = DATE '1999-01-01'
  ),
  -- combine web sales revenue and store return loss per item
  union_data AS (
    SELECT
      i.i_item_id   AS item_id,
      i.i_item_desc AS item_desc,
      'web_sales'   AS source,
      SUM(ws.ws_ext_sales_price) AS total_amount,
      ws.ws_web_page_sk AS web_page_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND wp.wp_char_count > 3000
    GROUP BY i.i_item_id, i.i_item_desc, ws.ws_web_page_sk

    UNION ALL

    SELECT
      i.i_item_id   AS item_id,
      i.i_item_desc AS item_desc,
      'store_returns' AS source,
      SUM(sr.sr_net_loss) AS total_amount,
      CAST(NULL AS integer) AS web_page_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND sr.sr_refunded_cash > 100
    GROUP BY i.i_item_id, i.i_item_desc
  )
SELECT
  ud.item_id,
  ud.item_desc,
  ud.source,
  ud.total_amount,
  sd.d_year,
  -- correlated scalar subquery: total catalog sales price for the same item on the same date
  (
    SELECT SUM(cs.cs_ext_sales_price)
    FROM catalog_sales cs
    WHERE cs.cs_item_sk = i.i_item_sk
      AND cs.cs_sold_date_sk = sd.d_date_sk
  ) AS catalog_sales_total,
  url_part
FROM union_data ud
CROSS JOIN single_date sd
LEFT JOIN item i ON i.i_item_id = ud.item_id
LEFT JOIN web_page wp ON wp.wp_web_page_sk = ud.web_page_sk
LEFT JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part) ON true
LIMIT 100
