WITH sales_agg AS (
  SELECT
    d.d_date,
    d.d_year,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
      SELECT SUM(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    ) AS inventory_on_date,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  RIGHT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY d.d_date, d.d_year, i.i_item_sk, i.i_item_id, i.i_product_name, d.d_date_sk
),
returns_agg AS (
  SELECT
    d.d_date,
    d.d_year,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_net_loss) AS total_return_loss,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS return_flag,
    (
      SELECT SUM(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    ) AS inventory_on_date,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS rank
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY d.d_date, d.d_year, i.i_item_sk, i.i_item_id, i.i_product_name, d.d_date_sk
)
SELECT *
FROM (
  SELECT
    'SALES'   AS src,
    s.d_date,
    s.i_item_id,
    s.i_product_name,
    s.total_net_paid,
    s.total_net_profit,
    s.profit_flag,
    s.inventory_on_date,
    s.rank,
    NULL      AS return_flag,
    NULL      AS return_rank
  FROM sales_agg s
  WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = s.i_item_sk
  )
  UNION ALL
  SELECT
    'RETURN'  AS src,
    r.d_date,
    r.i_item_id,
    r.i_product_name,
    r.total_return_amt   AS total_net_paid,
    r.total_return_loss  AS total_net_profit,
    NULL                 AS profit_flag,
    r.inventory_on_date,
    r.rank,
    r.return_flag,
    r.rank               AS return_rank
  FROM returns_agg r
  WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = r.i_item_sk
  )
) combined
ORDER BY combined.d_date DESC, combined.rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
