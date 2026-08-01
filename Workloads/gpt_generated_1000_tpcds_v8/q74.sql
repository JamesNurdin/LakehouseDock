WITH base AS (
    SELECT
        d_sold.d_year AS sold_year,
        p.p_promo_name AS promo_name,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_web_access
        ON wp.wp_access_date_sk = d_web_access.d_date_sk
    WHERE d_sold.d_year BETWEEN 1999 AND 2001
      AND p.p_purpose = 'Unknown'
),
agg AS (
    SELECT
        sold_year,
        promo_name,
        bill_gender,
        ship_gender,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_quantity) AS avg_quantity,
        COUNT(*) AS order_count
    FROM base
    GROUP BY ROLLUP (sold_year, promo_name, bill_gender, ship_gender)
)
SELECT
    sold_year,
    promo_name,
    bill_gender,
    ship_gender,
    total_profit,
    avg_quantity,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY sold_year NULLS LAST, total_profit DESC
LIMIT 100
