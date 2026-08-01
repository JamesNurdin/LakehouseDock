WITH intersect_stores AS (
    SELECT sr.sr_store_sk AS store_sk
    FROM store_returns sr
    INTERSECT
    SELECT s.s_store_sk
    FROM store s
),
main AS (
    SELECT
        s.s_store_name,
        cc.cc_division_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_sales,
        AVG(sr.sr_fee) AS avg_return_fee,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        lr.return_cnt,
        lr.distinct_reason_cnt,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM date_dim d
    FULL OUTER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    LEFT JOIN customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS return_cnt,
               COUNT(DISTINCT r2.r_reason_desc) AS distinct_reason_cnt
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) lr ON TRUE
    INNER JOIN intersect_stores ist
        ON ist.store_sk = s.s_store_sk
    WHERE cc.cc_division_name = 'cally'
      AND d.d_year = 2002
      AND hd_sr.hd_vehicle_count >= 2
      AND sr.sr_fee > 20
      AND ws.ws_net_profit > 0
      AND w.w_state = 'CA'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        s.s_store_name,
        cc.cc_division_name,
        d.d_year,
        lr.return_cnt,
        lr.distinct_reason_cnt
    HAVING
        SUM(ws.ws_net_profit) > 10000
        AND COUNT(DISTINCT sr.sr_ticket_number) > 5
)
SELECT
    s_store_name,
    cc_division_name,
    d_year,
    total_sales,
    avg_return_fee,
    total_returns,
    distinct_customers,
    return_cnt,
    distinct_reason_cnt,
    sales_rank
FROM main
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
