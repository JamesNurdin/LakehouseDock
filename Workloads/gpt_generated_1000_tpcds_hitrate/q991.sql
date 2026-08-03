WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT DISTINCT
    cs.cs_order_number,
    i_sold.i_product_name AS sold_product,
    i_ret.i_product_name   AS returned_product,
    i_web.i_product_name   AS web_return_product,
    d_sales.d_year,
    d_ret.d_year          AS return_year,
    d_web.d_year          AS web_return_year,
    cc.cc_name,
    p.p_promo_name,
    CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
    inv_agg.total_qty,
    y.target_year,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i_sold.i_item_sk) AS web_return_cnt
FROM catalog_sales cs
JOIN date_dim d_sales            ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN customer c_bill             ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN call_center cc              ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_sold                 ON cs.cs_item_sk = i_sold.i_item_sk
JOIN promotion p                 ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN inventory_agg inv_agg   ON inv_agg.inv_item_sk = i_sold.i_item_sk
                                 AND inv_agg.inv_date_sk = d_sales.d_date_sk
JOIN income_band ib              ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- Catalog Returns (exists check also)
JOIN catalog_returns cr          ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = i_sold.i_item_sk
JOIN date_dim d_cr               ON cr.cr_returned_date_sk = d_cr.d_date_sk
-- Store Returns and its item alias
JOIN store_returns sr            ON sr.sr_item_sk = i_sold.i_item_sk
JOIN item i_ret                  ON i_ret.i_item_sk = sr.sr_item_sk
JOIN date_dim d_ret              ON sr.sr_returned_date_sk = d_ret.d_date_sk
-- Web Returns and its item alias
JOIN web_returns wr             ON wr.wr_item_sk = i_sold.i_item_sk
JOIN item i_web                  ON i_web.i_item_sk = wr.wr_item_sk
JOIN date_dim d_web              ON wr.wr_returned_date_sk = d_web.d_date_sk
-- Cross join with a small computed set
CROSS JOIN (VALUES 2022, 2023) AS y(target_year)
WHERE d_sales.d_year = y.target_year
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr_exists
        WHERE cr_exists.cr_order_number = cs.cs_order_number
          AND cr_exists.cr_return_amount > 0
    )
LIMIT 100
