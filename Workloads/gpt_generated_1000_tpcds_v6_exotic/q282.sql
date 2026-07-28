WITH
joined AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cd_bill.cd_credit_rating,
        sm.sm_ship_mode_id,
        inv_fact.inv_quantity_on_hand AS inv_qty_fact,
        inv_promo.inv_quantity_on_hand AS inv_qty_promo
    FROM catalog_sales cs
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i_fact
        ON cs.cs_item_sk = i_fact.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i_promo
        ON p.p_item_sk = i_promo.i_item_sk
    JOIN inventory inv_fact
        ON inv_fact.inv_item_sk = i_fact.i_item_sk
    JOIN inventory inv_promo
        ON inv_promo.inv_item_sk = i_promo.i_item_sk
    JOIN item i_join
        ON i_fact.i_item_sk = i_join.i_item_sk
    WHERE cs.cs_net_profit > 0
      AND cd_bill.cd_credit_rating IN ('Good', 'High Risk')
      AND sm.sm_type = 'AIR'
      AND inv_fact.inv_quantity_on_hand > 200
),
agg AS (
    SELECT
        cd_credit_rating,
        sm_ship_mode_id,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(cs_ext_discount_amt) AS avg_discount,
        SUM(inv_qty_fact) AS total_inv_qty_fact,
        SUM(inv_qty_promo) AS total_inv_qty_promo,
        CASE WHEN SUM(cs_net_profit) > 50000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM joined
    GROUP BY cd_credit_rating, sm_ship_mode_id
)
SELECT
    cd_credit_rating,
    sm_ship_mode_id,
    total_profit,
    order_cnt,
    avg_discount,
    profit_level,
    RANK() OVER (PARTITION BY cd_credit_rating ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
