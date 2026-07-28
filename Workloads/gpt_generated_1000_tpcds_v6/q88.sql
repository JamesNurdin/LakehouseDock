WITH
    store_sales_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_customer_sk,
            ss_cdemo_sk,
            ss_addr_sk,
            SUM(ss_net_paid)          AS total_net_paid,
            SUM(ss_quantity)          AS total_quantity
        FROM store_sales
        GROUP BY
            ss_store_sk,
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_customer_sk,
            ss_cdemo_sk,
            ss_addr_sk
    ),
    catalog_sales_agg AS (
        SELECT
            cs_sold_date_sk,
            cs_promo_sk,
            cs_ship_mode_sk,
            SUM(cs_net_paid)          AS total_cs_net_paid,
            SUM(cs_quantity)          AS total_cs_quantity
        FROM catalog_sales
        GROUP BY
            cs_sold_date_sk,
            cs_promo_sk,
            cs_ship_mode_sk
    ),
    web_returns_agg AS (
        SELECT
            wr_returned_date_sk,
            wr_reason_sk,
            SUM(wr_net_loss)          AS total_return_loss,
            COUNT(*)                   AS return_cnt
        FROM web_returns
        GROUP BY
            wr_returned_date_sk,
            wr_reason_sk
    ),
    ship_mode_agg AS (
        SELECT
            cs_ship_mode_sk,
            cs_sold_date_sk,
            SUM(cs_net_paid)          AS ship_mode_sales
        FROM catalog_sales
        GROUP BY
            cs_ship_mode_sk,
            cs_sold_date_sk
    ),
    time_agg AS (
        SELECT
            ss_sold_time_sk,
            SUM(ss_quantity)          AS qty_by_time
        FROM store_sales
        GROUP BY ss_sold_time_sk
    )
SELECT
    d.d_year,
    s.s_store_name,
    s.s_state,
    SUM(ss.total_net_paid)                              AS store_total_net_paid,
    SUM(cs.total_cs_net_paid)                            AS catalog_total_net_paid,
    SUM(wr.total_return_loss)                           AS total_return_loss,
    SUM(smag.ship_mode_sales)                            AS ship_mode_total_sales,
    SUM(ta.qty_by_time)                                 AS total_qty_by_time,
    CASE
        WHEN s.s_state = 'NY' THEN SUM(ss.total_net_paid) * 1.1
        ELSE SUM(ss.total_net_paid)
    END                                                  AS adjusted_store_sales,
    p.p_promo_name,
    p2.p_promo_name                                      AS start_promo_name,
    r.r_reason_desc,
    ws.web_name,
    cc.cc_name,
    cp.cp_department
FROM store_sales_agg ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN time_agg ta
    ON ss.ss_sold_time_sk = ta.ss_sold_time_sk
LEFT JOIN catalog_sales_agg cs
    ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN promotion p2
    ON p2.p_start_date_sk = d.d_date_sk
LEFT JOIN ship_mode_agg smag
    ON smag.cs_sold_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = smag.cs_ship_mode_sk
LEFT JOIN web_returns_agg wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
    ON r.r_reason_sk = wr.wr_reason_sk
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    p2.p_promo_name,
    r.r_reason_desc,
    ws.web_name,
    cc.cc_name,
    cp.cp_department
ORDER BY adjusted_store_sales DESC
LIMIT 100
