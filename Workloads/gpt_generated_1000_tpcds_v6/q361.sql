WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_profit,
        cs.cs_ext_list_price,
        cs.cs_quantity,
        d_sold.d_year,
        d_sold.d_date,
        p.p_promo_name,
        sm.sm_type,
        hd_bill.hd_buy_potential,
        CASE 
            WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
            WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN promotion p2
        ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = wr.wr_reason_sk
          AND r2.r_reason_desc = 'Customer Not Satisfied'
    )
),
agg AS (
    SELECT
        d_year,
        p_promo_name,
        sm_type,
        hd_buy_potential,
        profit_category,
        SUM(cs_net_profit) AS total_profit,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT cs_sold_date_sk) AS days_sold,
        SUM(cs_quantity) AS total_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(cs_ext_list_price) AS total_list_price
    FROM base
    GROUP BY
        d_year,
        p_promo_name,
        sm_type,
        hd_buy_potential,
        profit_category
    HAVING SUM(cs_net_profit) > 10000
)
SELECT
    d_year,
    p_promo_name,
    sm_type,
    hd_buy_potential,
    profit_category,
    total_profit,
    avg_inventory_on_hand,
    days_sold,
    total_quantity,
    total_return_amount,
    total_list_price,
    total_list_price / NULLIF(total_quantity, 0) AS avg_price_per_unit,
    total_profit / NULLIF(total_quantity, 0) AS profit_per_unit,
    SUM(total_profit) OVER (
        PARTITION BY d_year
        ORDER BY total_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_year_profit
FROM agg
ORDER BY total_profit DESC
LIMIT 100
