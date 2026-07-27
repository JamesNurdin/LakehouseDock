WITH base AS (
    SELECT
        p.p_promo_id,
        w.w_warehouse_id,
        ws.ws_net_paid AS sales_amount,
        sr.sr_return_amt_inc_tax AS return_amount,
        hd_ws.hd_buy_potential,
        ib.ib_upper_bound,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        sr.sr_return_quantity,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        td.t_hour,
        site.web_country
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib
        ON hd_ws.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_hdemo_sk = hd_ws.hd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND ib.ib_upper_bound >= 100000
      AND hd_ws.hd_buy_potential = '>10000'
      AND w.w_zip = '42477'
      AND td.t_hour BETWEEN 9 AND 17
      AND site.web_country = 'United States'
),
agg_by_promo_warehouse AS (
    SELECT
        p_promo_id,
        w_warehouse_id,
        SUM(sales_amount) AS total_sales,
        SUM(COALESCE(return_amount, 0)) AS total_returns,
        SUM(sales_amount) - SUM(COALESCE(return_amount, 0)) AS net_revenue,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY p_promo_id, w_warehouse_id
)
SELECT
    p_promo_id,
    AVG(net_revenue) AS avg_net_revenue,
    SUM(total_sales) AS agg_sales,
    SUM(total_returns) AS agg_returns,
    COUNT(*) AS warehouse_count
FROM agg_by_promo_warehouse
GROUP BY p_promo_id
HAVING AVG(net_revenue) > 5000
ORDER BY avg_net_revenue DESC
LIMIT 100
