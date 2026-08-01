-- Goal: Summarize net sales, profit and return loss for 2001 California stores serving households with medium buying potential, categorize households by size, rank stores by net sales, and return the top store per store with high average profit.
WITH sales_agg AS (
    SELECT
        s.ss_store_sk AS store_sk,
        d_sale.d_year AS year,
        ca.ca_state AS state,
        hd.hd_buy_potential AS household_buy_potential,
        hd.hd_dep_count,
        SUM(s.ss_net_paid) AS total_net_paid,
        SUM(s.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        CASE WHEN hd.hd_dep_count >= 4 THEN 'Large' ELSE 'Small' END AS household_size_category
    FROM store_sales s
    JOIN date_dim d_sale ON s.ss_sold_date_sk = d_sale.d_date_sk
    JOIN time_dim t_sale ON s.ss_sold_time_sk = t_sale.t_time_sk
    JOIN household_demographics hd ON s.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON s.ss_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name, p2.p_channel_radio
        FROM promotion p2
        WHERE p2.p_promo_sk = s.ss_promo_sk
    ) promo
    LEFT JOIN store_returns sr
        ON s.ss_ticket_number = sr.sr_ticket_number
       AND s.ss_item_sk = sr.sr_item_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    WHERE d_sale.d_year = 2001
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '1001-5000'
      AND promo.p_channel_radio = 'N'
    GROUP BY
        s.ss_store_sk,
        d_sale.d_year,
        ca.ca_state,
        hd.hd_buy_potential,
        hd.hd_dep_count
)
SELECT *
FROM (
    SELECT
        store_sk,
        year,
        state,
        household_buy_potential,
        household_size_category,
        total_net_paid,
        total_net_profit,
        total_return_loss,
        sales_cnt,
        AVG(total_net_profit) OVER (PARTITION BY store_sk) AS avg_total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY store_sk ORDER BY total_net_paid DESC) AS rn
    FROM sales_agg
) q
WHERE q.rn = 1
  AND q.avg_total_net_profit > 1000
LIMIT 100
