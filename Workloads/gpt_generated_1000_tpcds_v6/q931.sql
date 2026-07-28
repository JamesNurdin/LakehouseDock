WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        AVG(cs.cs_sales_price) AS avg_catalog_price,
        AVG(ss.ss_sales_price) AS avg_store_price
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd2
        ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca_ship
        ON ss.ss_addr_sk = ca_ship.ca_address_sk
    WHERE
        cs.cs_quantity > 5
        AND ss.ss_quantity > 3
        AND c.c_birth_country = 'CAMBODIA'
        AND ib.ib_upper_bound = 100000
        AND ca_bill.ca_state = 'CA'
        AND ca_ship.ca_state = 'CA'
        AND cs.cs_sales_price > 100
        AND ss.ss_sales_price > 150
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.ib_income_band_sk,
    s.catalog_net_profit,
    s.store_net_profit,
    (s.catalog_net_profit + s.store_net_profit) AS total_net_profit,
    RANK() OVER (ORDER BY (s.catalog_net_profit + s.store_net_profit) DESC) AS profit_rank,
    SUM(s.catalog_net_profit + s.store_net_profit) OVER (PARTITION BY s.ib_income_band_sk) AS income_band_total_profit
FROM sales_agg s
WHERE s.catalog_orders > (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(DISTINCT cs.cs_order_number) AS cnt
        FROM catalog_sales cs
        GROUP BY cs.cs_bill_customer_sk
    ) sub
)
ORDER BY total_net_profit DESC
LIMIT 100
