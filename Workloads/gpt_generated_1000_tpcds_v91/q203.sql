WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        d.d_year,
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_zip LIKE '9%'
      AND regexp_like(ca.ca_city, '^A.*')
      AND regexp_like(hd.hd_buy_potential, '^[A-Z]{2}.*')
      AND ss.ss_wholesale_cost > (SELECT AVG(ss2.ss_wholesale_cost) FROM store_sales ss2)
),
agg_sales AS (
    SELECT
        ca_state,
        d_year,
        concat(ca_state, '-', substr(ca_city, 1, 3)) AS state_city_prefix,
        count(*) AS sales_cnt,
        sum(ss_net_paid) AS total_net_paid,
        sum(ss_net_profit) AS total_net_profit,
        avg(ss_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM base_sales
    GROUP BY ca_state, d_year, concat(ca_state, '-', substr(ca_city, 1, 3))
    HAVING sum(ss_net_paid) > 50000
)
SELECT
    ag.ca_state,
    ag.d_year,
    ag.state_city_prefix,
    ag.sales_cnt,
    ag.total_net_paid,
    ag.total_net_profit,
    ag.avg_net_paid_inc_tax,
    (
        SELECT count(*)
        FROM store_sales ss3
        JOIN household_demographics hd3 ON ss3.ss_hdemo_sk = hd3.hd_demo_sk
        JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
        JOIN customer_address ca3 ON ss3.ss_addr_sk = ca3.ca_address_sk
        WHERE ca3.ca_state = ag.ca_state
          AND ss3.ss_net_profit > ag.total_net_profit
    ) AS higher_profit_sales_in_state,
    (
        SELECT max(ss4.ss_net_profit)
        FROM store_sales ss4
    ) AS max_net_profit_overall
FROM agg_sales ag
ORDER BY ag.total_net_profit DESC
LIMIT 100
