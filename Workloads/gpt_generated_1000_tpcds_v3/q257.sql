-- Goal: Analyze web returns for the year 2001 by store, website, promotion and customer, aggregating return amounts and net loss, and rank stores by total return amount.
WITH
    date_ret AS (
        SELECT d_date_sk, d_date, d_year
        FROM date_dim
    ),
    date_ship AS (
        SELECT d_date_sk, d_date AS ship_date
        FROM date_dim
    ),
    date_sales AS (
        SELECT d_date_sk, d_date AS sales_date
        FROM date_dim
    ),
    date_promo_start AS (
        SELECT d_date_sk, d_date AS promo_start_date
        FROM date_dim
    ),
    date_promo_end AS (
        SELECT d_date_sk, d_date AS promo_end_date
        FROM date_dim
    ),
    date_store_closed AS (
        SELECT d_date_sk, d_date AS store_closed_date
        FROM date_dim
    ),
    date_site_open AS (
        SELECT d_date_sk, d_date AS site_open_date
        FROM date_dim
    ),
    date_site_close AS (
        SELECT d_date_sk, d_date AS site_close_date
        FROM date_dim
    ),
    agg AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            ws.web_site_id,
            ws.web_name,
            p.p_promo_id,
            p.p_promo_name,
            c.c_customer_id,
            hd.hd_buy_potential,
            date_ret.d_year,
            SUM(wr.wr_return_amt) AS total_return_amount,
            SUM(wr.wr_net_loss) AS total_net_loss,
            COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
        FROM
            web_returns wr
            JOIN date_ret ON wr.wr_returned_date_sk = date_ret.d_date_sk
            JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
            JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
            JOIN customer cr ON wr.wr_returning_customer_sk = cr.c_customer_sk
            JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
            JOIN store s ON s.s_closed_date_sk = date_ret.d_date_sk
            JOIN web_site ws ON ws.web_open_date_sk = date_ret.d_date_sk
            JOIN promotion p ON p.p_start_date_sk = date_ret.d_date_sk
            JOIN date_ship ds ON c.c_first_shipto_date_sk = ds.d_date_sk
            JOIN date_sales dsa ON c.c_first_sales_date_sk = dsa.d_date_sk
            JOIN date_promo_start dps ON p.p_start_date_sk = dps.d_date_sk
            JOIN date_promo_end dpe ON p.p_end_date_sk = dpe.d_date_sk
            JOIN date_store_closed dsc ON s.s_closed_date_sk = dsc.d_date_sk
            JOIN date_site_open dso ON ws.web_open_date_sk = dso.d_date_sk
            JOIN date_site_close dsc2 ON ws.web_close_date_sk = dsc2.d_date_sk
            JOIN household_demographics hd_current ON c.c_current_hdemo_sk = hd_current.hd_demo_sk
        WHERE
            date_ret.d_year = 2001
            AND hd.hd_vehicle_count > 1
            AND p.p_discount_active = 'Y'
        GROUP BY
            s.s_store_id,
            s.s_store_name,
            ws.web_site_id,
            ws.web_name,
            p.p_promo_id,
            p.p_promo_name,
            c.c_customer_id,
            hd.hd_buy_potential,
            date_ret.d_year
    )
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amount DESC) AS store_return_rank
FROM agg
ORDER BY total_net_loss DESC, store_return_rank
LIMIT 100
