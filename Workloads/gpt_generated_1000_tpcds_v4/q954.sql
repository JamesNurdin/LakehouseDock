WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 100
      AND inv_warehouse_sk IN (1, 8, 17)
    GROUP BY inv_item_sk, inv_warehouse_sk
),
store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_geography_class,
        SUM(cr.cr_net_loss) AS catalog_loss,
        SUM(sr.sr_net_loss) AS store_loss
    FROM inv_agg ia
    JOIN item i ON ia.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
    WHERE i.i_current_price > 20
      AND i.i_color = 'Red'
      AND s.s_manager IN ('Ricky Nichols', 'Matt Frederick')
      AND s.s_geography_class <> 'Unknown'
      AND cd_sr.cd_gender = 'M'
      AND cd_cr.cd_credit_rating = 'Excellent'
      AND cr.cr_return_tax > 10
    GROUP BY s.s_store_sk, s.s_store_name, s.s_geography_class
)
SELECT
    s_store_sk,
    s_store_name,
    s_geography_class,
    catalog_loss,
    store_loss,
    (catalog_loss + store_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY s_geography_class ORDER BY (catalog_loss + store_loss) DESC) AS geo_rank
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 100
