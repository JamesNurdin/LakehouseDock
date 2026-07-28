WITH base AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_category,
        i.i_manufact,
        i.i_item_sk,
        t_sold.t_hour,
        cd_bill.cd_gender,
        hd_bill.hd_buy_potential
    FROM catalog_sales cs
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN time_dim t_dummy
        ON cs.cs_sold_time_sk = t_dummy.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN promotion p_item
        ON i.i_item_sk = p_item.p_item_sk
    WHERE p.p_discount_active <> 'Y'
),
agg AS (
    SELECT
        i_category,
        i_manufact,
        t_hour,
        cd_gender,
        hd_buy_potential,
        MAX(i_item_sk) AS item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(cs_net_profit) AS avg_profit,
        CASE WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM base
    GROUP BY i_category, i_manufact, t_hour, cd_gender, hd_buy_potential
    HAVING SUM(cs_ext_sales_price) > 50000
)
SELECT
    i_category,
    i_manufact,
    t_hour,
    cd_gender,
    hd_buy_potential,
    total_sales,
    order_cnt,
    avg_profit,
    sales_level,
    RANK() OVER (PARTITION BY i_manufact ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY i_category) AS category_total_sales
FROM agg
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p_ex
    WHERE p_ex.p_item_sk = agg.item_sk
      AND p_ex.p_discount_active = 'Y'
)
ORDER BY total_sales DESC
LIMIT 100
