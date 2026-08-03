WITH base AS (
    SELECT
        s.s_store_id AS s_store_id,
        p.p_promo_id AS p_promo_id,
        td1.t_hour    AS t_hour,
        ss.ss_ext_sales_price      AS ss_ext_sales_price,
        sr.sr_return_amt_inc_tax   AS sr_return_amt_inc_tax,
        cs.cs_net_paid_inc_tax     AS cs_net_paid_inc_tax,
        cc.cc_class                AS cc_class,
        sm.sm_carrier              AS sm_carrier,
        ca.ca_state                AS ca_state,
        loc                        AS location
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td1          ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN time_dim td2          ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN catalog_sales cs      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td3          ON cs.cs_sold_time_sk = td3.t_time_sk
    CROSS JOIN UNNEST(array[ s.s_city, s.s_state ]) AS t(loc)
    WHERE s.s_state = 'CA'
      AND cc.cc_class = 'medium'
      AND sm.sm_carrier = 'UPS'
),
agg AS (
    SELECT
        s_store_id,
        p_promo_id,
        t_hour,
        SUM(ss_ext_sales_price)   AS total_sales,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        AVG(cs_net_paid_inc_tax)   AS avg_net_paid
    FROM base
    GROUP BY s_store_id, p_promo_id, t_hour
)
SELECT
    s_store_id,
    SUM(total_sales)   AS sum_sales,
    SUM(total_returns) AS sum_returns,
    AVG(avg_net_paid)  AS avg_net_paid
FROM (
    SELECT s_store_id, total_sales, total_returns, avg_net_paid FROM agg WHERE total_sales > 10000
    UNION
    SELECT s_store_id, total_sales, total_returns, avg_net_paid FROM agg WHERE total_returns > 5000
) u
GROUP BY s_store_id
HAVING SUM(total_sales) > 20000
ORDER BY sum_sales DESC
OFFSET 0 FETCH NEXT 10 ROWS ONLY
