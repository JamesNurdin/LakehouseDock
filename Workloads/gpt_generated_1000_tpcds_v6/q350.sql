WITH sales_time AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        t.t_time,
        t.t_sub_shift
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND cs.cs_ext_ship_cost > 500
),
promo_ship AS (
    SELECT
        st.*, 
        p.p_promo_id,
        p.p_channel_radio,
        p.p_cost,
        sm.sm_type,
        sm.sm_carrier
    FROM sales_time st
    JOIN promotion p
      ON st.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON st.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_radio = 'N'
      AND sm.sm_type = 'AIR'
),
sales_cust AS (
    SELECT
        ps.*, 
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM promo_ship ps
    JOIN customer_demographics cd
      ON ps.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
),
sales_returns AS (
    SELECT
        sc.*, 
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_item_sk
    FROM sales_cust sc
    JOIN web_returns wr
      ON wr.wr_returned_time_sk = sc.cs_sold_time_sk
    WHERE wr.wr_return_amt > 100
)
SELECT DISTINCT
    sr.cs_order_number,
    sr.cs_sold_date_sk,
    sr.p_promo_id,
    sr.sm_type,
    sr.cd_gender,
    sr.t_time,
    sr.cs_ext_sales_price,
    sr.cs_net_profit,
    sr.wr_return_amt,
    sr.wr_net_loss,
    SUM(sr.cs_ext_sales_price) OVER (
        PARTITION BY sr.p_promo_id 
        ORDER BY sr.cs_sold_date_sk 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sales_price,
    RANK() OVER (
        PARTITION BY sr.p_promo_id 
        ORDER BY sr.cs_net_profit DESC
    ) AS profit_rank,
    CASE 
        WHEN sr.wr_return_amt > (
            SELECT AVG(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = sr.wr_item_sk
        ) THEN 'HIGH_RETURN'
        ELSE 'NORMAL_RETURN'
    END AS return_category
FROM sales_returns sr
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = sr.cs_promo_sk
      AND p2.p_discount_active = 'Y'
)
ORDER BY sr.cs_sold_date_sk DESC, profit_rank
LIMIT 100
