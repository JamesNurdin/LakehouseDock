WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        p.p_promo_sk,
        p.p_discount_active,
        wr.wr_return_amt,
        c.c_birth_year,
        s.s_store_name,
        cc.cc_name
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_site wsi
        ON ws.ws_web_site_sk = wsi.web_site_sk
    LEFT JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND c.c_birth_year >= 1950
      AND p.p_discount_active = 'Y'
)
SELECT
    agg.year,
    agg.month_seq,
    agg.total_sales,
    agg.total_returns,
    agg.avg_net_profit,
    agg.total_promotions,
    agg.avg_quantity
FROM (
    SELECT
        d_year AS year,
        d_month_seq AS month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(wr_return_amt) AS total_returns,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT p_promo_sk) AS total_promotions,
        AVG(ws_quantity) AS avg_quantity
    FROM base
    GROUP BY d_year, d_month_seq
) agg
WHERE agg.total_sales > 10000
ORDER BY agg.year DESC, agg.month_seq ASC
LIMIT 100
