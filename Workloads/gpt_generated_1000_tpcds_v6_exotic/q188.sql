/*
  Goal: Analyze sales performance by store, hour of day and item category for promotions delivered via direct mail, focusing on higher‑vehicle households and recent promotion start dates. The query joins all 11 selected TPC‑DS tables, applies selective filters, aggregates key sales metrics, adds a scalar subquery, computes windowed totals and ranking, orders the result and limits to the top 100 rows.
*/
WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        td.t_hour,
        i.i_category,
        i.i_current_price,
        s.s_store_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_channel_dmail,
        p.p_start_date_sk,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_start_date_sk BETWEEN 2450530 AND 2450625
      AND hd.hd_vehicle_count >= 2
),
agg_sales AS (
    SELECT
        fs.s_store_name,
        fs.t_hour,
        fs.i_category,
        fs.ib_lower_bound,
        fs.ib_upper_bound,
        SUM(fs.ss_ext_sales_price)           AS total_sales,
        SUM(fs.ss_net_profit)                AS total_profit,
        AVG(fs.i_current_price)              AS avg_item_price,
        COUNT(DISTINCT fs.ss_ticket_number)  AS transaction_cnt,
        (SELECT COUNT(*) FROM promotion WHERE p_channel_email = 'Y') AS email_promo_count
    FROM filtered_sales fs
    JOIN inventory inv   ON fs.ss_item_sk = inv.inv_item_sk
    JOIN warehouse w     ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer c      ON fs.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON fs.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        fs.s_store_name,
        fs.t_hour,
        fs.i_category,
        fs.ib_lower_bound,
        fs.ib_upper_bound
)
SELECT
    a.s_store_name,
    a.t_hour,
    a.i_category,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.total_sales,
    a.total_profit,
    a.avg_item_price,
    a.transaction_cnt,
    a.email_promo_count,
    SUM(a.total_sales) OVER (PARTITION BY a.s_store_name) AS store_sales_total,
    RANK() OVER (ORDER BY a.total_sales DESC)               AS global_sales_rank
FROM agg_sales a
ORDER BY a.total_sales DESC, a.s_store_name
LIMIT 100
