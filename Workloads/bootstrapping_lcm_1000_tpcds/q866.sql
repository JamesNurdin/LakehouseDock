WITH sales_agg AS (
    SELECT
        cs.cs_item_sk AS cs_item_sk,
        cd_bill.cd_gender AS cd_gender,
        cd_bill.cd_marital_status AS cd_marital_status,
        s.s_state AS s_state,
        sold.d_year AS d_year,
        sold.d_moy AS d_moy,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT pr.p_promo_id) AS distinct_promotions
    FROM catalog_sales cs
    JOIN date_dim sold ON cs.cs_sold_date_sk = sold.d_date_sk
    JOIN date_dim ship ON cs.cs_ship_date_sk = ship.d_date_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion pr ON cs.cs_promo_sk = pr.p_promo_sk
    JOIN date_dim promo_start ON pr.p_start_date_sk = promo_start.d_date_sk
    JOIN date_dim promo_end ON pr.p_end_date_sk = promo_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = sold.d_date_sk
    JOIN date_dim store_date ON s.s_closed_date_sk = store_date.d_date_sk
    WHERE sold.d_year = 2022
      AND promo_start.d_date <= sold.d_date
      AND promo_end.d_date >= sold.d_date
    GROUP BY
        cs.cs_item_sk,
        cd_bill.cd_gender,
        cd_bill.cd_marital_status,
        s.s_state,
        sold.d_year,
        sold.d_moy
)
SELECT
    cs_item_sk,
    cd_gender,
    cd_marital_status,
    s_state,
    d_year,
    d_moy,
    total_net_profit,
    total_quantity,
    avg_discount,
    distinct_promotions,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
