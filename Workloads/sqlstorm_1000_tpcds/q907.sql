WITH
sales_agg AS (
  SELECT 
    item_sk,
    sum(quantity) AS total_qty,
    sum(ext_sales_price) AS total_sales_amount,
    sum(net_paid) AS total_net_paid,
    sum(net_profit) AS total_net_profit,
    sum(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS qty_store,
    sum(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS qty_web,
    sum(CASE WHEN channel = 'catalog' THEN quantity ELSE 0 END) AS qty_catalog
  FROM (
    SELECT 
      cs.cs_item_sk AS item_sk,
      cs.cs_quantity AS quantity,
      cs.cs_ext_sales_price AS ext_sales_price,
      cs.cs_net_paid AS net_paid,
      cs.cs_net_profit AS net_profit,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT 
      ss.ss_item_sk AS item_sk,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS ext_sales_price,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT 
      ws.ws_item_sk AS item_sk,
      ws.ws_quantity AS quantity,
      ws.ws_ext_sales_price AS ext_sales_price,
      ws.ws_net_paid AS net_paid,
      ws.ws_net_profit AS net_profit,
      'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ) s
  GROUP BY item_sk
),
returns_agg AS (
  SELECT 
    item_sk,
    sum(return_quantity) AS total_return_qty,
    sum(return_amount) AS total_return_amount,
    sum(net_loss) AS total_net_loss
  FROM (
    SELECT 
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS return_quantity,
      cr.cr_return_amount AS return_amount,
      cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT 
      sr.sr_item_sk AS item_sk,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_return_amt AS return_amount,
      sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT 
      wr.wr_item_sk AS item_sk,
      wr.wr_return_quantity AS return_quantity,
      wr.wr_return_amt AS return_amount,
      wr.wr_net_loss AS net_loss
    FROM web_returns wr
  ) r
  GROUP BY item_sk
),
call_center_agg AS (
  SELECT 
    cs.cs_item_sk AS item_sk,
    count(DISTINCT cs.cs_call_center_sk) AS distinct_call_centers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY cs.cs_item_sk
),
avg_discount_agg AS (
  SELECT 
    i_item_sk,
    avg(CASE WHEN ext_sales_price > 0 THEN ext_discount_amt / ext_sales_price ELSE NULL END) AS avg_discount_ratio
  FROM (
    SELECT cs.cs_item_sk AS i_item_sk,
      cs.cs_ext_discount_amt AS ext_discount_amt,
      cs.cs_ext_sales_price AS ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT ss.ss_item_sk,
      ss.ss_ext_discount_amt,
      ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT ws.ws_item_sk,
      ws.ws_ext_discount_amt,
      ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ) disc
  GROUP BY i_item_sk
),
sold_items AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_manufact,
    CONCAT_WS(' - ', i.i_category, i.i_manufact) AS cat_manuf,
    COALESCE(s.total_qty, 0) AS total_quantity_sold,
    COALESCE(s.total_sales_amount, 0.0) AS total_sales_amount,
    COALESCE(s.total_net_paid, 0.0) AS total_net_paid,
    COALESCE(s.total_net_profit, 0.0) AS total_net_profit,
    COALESCE(r.total_return_qty, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0.0) AS total_return_amount,
    COALESCE(s.total_net_profit, 0.0) - COALESCE(r.total_net_loss, 0.0) AS net_profit_after_returns,
    COALESCE(ad.avg_discount_ratio, 0.0) AS avg_discount_ratio,
    COALESCE(cc.distinct_call_centers, 0) AS distinct_call_centers,
    RANK() OVER (PARTITION BY i.i_category ORDER BY COALESCE(s.total_net_profit,0.0) DESC) AS profit_rank_within_category,
    CASE 
      WHEN COALESCE(s.total_net_profit,0.0) - COALESCE(r.total_net_loss,0.0) > 20000 THEN 'High'
      WHEN COALESCE(s.total_net_profit,0.0) - COALESCE(r.total_net_loss,0.0) BETWEEN 5000 AND 20000 THEN 'Medium'
      ELSE 'Low'
    END AS profit_level,
    (SELECT count(*) 
       FROM promotion p2 
       WHERE p2.p_item_sk = i.i_item_sk
         AND p2.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
         AND p2.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2000)
    ) AS active_promo_count,
    p.p_promo_name
  FROM item i
  LEFT JOIN sales_agg s ON i.i_item_sk = s.item_sk
  LEFT JOIN returns_agg r ON i.i_item_sk = r.item_sk
  LEFT JOIN call_center_agg cc ON i.i_item_sk = cc.item_sk
  LEFT JOIN avg_discount_agg ad ON i.i_item_sk = ad.i_item_sk
  LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2000)
  WHERE (COALESCE(s.total_qty,0) > 100 OR COALESCE(r.total_return_qty,0) > 0)
    AND (COALESCE(s.total_net_profit,0.0) - COALESCE(r.total_net_loss,0.0)) > 500
),
unsold_items AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_manufact,
    CONCAT_WS(' - ', i.i_category, i.i_manufact) AS cat_manuf,
    0 AS total_quantity_sold,
    0.0 AS total_sales_amount,
    0.0 AS total_net_paid,
    0.0 AS total_net_profit,
    0 AS total_return_quantity,
    0.0 AS total_return_amount,
    0.0 AS net_profit_after_returns,
    0.0 AS avg_discount_ratio,
    0 AS distinct_call_centers,
    CAST(NULL AS BIGINT) AS profit_rank_within_category,
    'Low' AS profit_level,
    0 AS active_promo_count,
    CAST(NULL AS VARCHAR) AS p_promo_name
  FROM item i
  WHERE i.i_item_sk NOT IN (SELECT item_sk FROM sales_agg)
)
SELECT *
FROM sold_items
UNION ALL
SELECT *
FROM unsold_items
ORDER BY cat_manuf, net_profit_after_returns DESC
LIMIT 100
