WITH intersect_items AS (
    SELECT i.i_item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_quantity > 5
    INTERSECT
    SELECT i2.i_item_sk
    FROM catalog_sales cs
    JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
    WHERE cs.cs_quantity > 3
),
base_aggregated AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales_amount,
        MAX(p.p_discount_active) AS promo_discount_active
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    WHERE
        ss.ss_quantity > 2
        AND cr.cr_return_amount > 30
        AND p.p_channel_radio = 'N'
        AND hd.hd_vehicle_count > 0
        AND i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category
)
SELECT
    ba.i_item_id,
    ba.i_brand,
    ba.i_category,
    ba.total_quantity,
    ba.total_sales_amount,
    ba.total_net_profit,
    RANK() OVER (ORDER BY ba.total_net_profit DESC) AS profit_rank,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_item_sk = ba.i_item_sk
    ) AS total_store_return_amount
FROM base_aggregated ba
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = ba.i_item_sk
      AND sr.sr_return_tax > 20
)
ORDER BY profit_rank
LIMIT 100
