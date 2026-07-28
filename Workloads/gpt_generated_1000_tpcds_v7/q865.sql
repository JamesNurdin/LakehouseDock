WITH sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_item_id,
        i.i_current_price,
        i.i_manufact,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 10.00
      AND hd.hd_vehicle_count >= 0
),
inventory_joined AS (
    SELECT
        se.*,
        inv.inv_quantity_on_hand
    FROM sales_enriched se
    JOIN inventory inv
        ON inv.inv_date_sk = se.ss_sold_date_sk
        AND inv.inv_item_sk = se.ss_item_sk
),
web_returns_joined AS (
    SELECT
        ijn.*,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM inventory_joined ijn
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = ijn.ss_sold_date_sk
        AND wr.wr_item_sk = ijn.ss_item_sk
        AND wr.wr_refunded_customer_sk = ijn.ss_customer_sk
)
SELECT
    d_year,
    i_manufact,
    t_hour,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_profit) DESC) AS profit_rank_by_year
FROM web_returns_joined
GROUP BY d_year, i_manufact, t_hour
ORDER BY d_year, profit_rank_by_year
LIMIT 100
