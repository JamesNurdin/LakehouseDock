WITH purchase_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
),
return_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
),
non_returning_customers AS (
    SELECT pc.customer_sk
    FROM purchase_customers pc
    EXCEPT
    SELECT rc.customer_sk FROM return_customers rc
),
joined_all AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d_sold.d_year,
        cp.cp_catalog_number,
        p.p_channel_dmail,
        cc.cc_name,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE c.c_customer_sk IN (SELECT customer_sk FROM non_returning_customers)
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d_sold.d_year,
        cp.cp_catalog_number,
        p.p_channel_dmail,
        cc.cc_name,
        hd.hd_buy_potential,
        ib.ib_lower_bound
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn,
    u.c_customer_sk,
    u.c_first_name,
    u.c_last_name,
    u.d_year,
    u.cp_catalog_number,
    u.p_channel_dmail,
    u.cc_name,
    u.hd_buy_potential,
    u.ib_lower_bound,
    u.total_profit,
    u.sales_cnt,
    r_small.r_reason_id,
    v.multiplier
FROM (
    SELECT DISTINCT * FROM joined_all
    UNION
    SELECT DISTINCT * FROM joined_all
) AS u
CROSS JOIN (SELECT r_reason_id FROM reason LIMIT 5) AS r_small
CROSS JOIN (VALUES 1, 2, 3) AS v(multiplier)
ORDER BY rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
