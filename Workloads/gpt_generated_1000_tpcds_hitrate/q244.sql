WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        dd.d_year,
        dd.d_month_seq,
        ca.ca_state,
        ca.ca_gmt_offset,
        s.s_store_id,
        s.s_state AS store_state,
        s.s_tax_percentage,
        w.w_warehouse_id,
        w.w_state AS warehouse_state,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_refunded_cash,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE dd.d_year = 2001
      AND s.s_state = 'CA'
      AND ss.ss_net_profit > 1000
      AND sr.sr_refunded_cash < 500
      AND ws.ws_net_paid_inc_tax > 5000
      AND w.w_state = 'TX'
      AND ca.ca_gmt_offset BETWEEN -5 AND 5
),
agg AS (
    SELECT
        dd.d_year,
        s.s_state AS store_state,
        w.w_state AS warehouse_state,
        s.s_store_id AS s_store_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(sr.sr_refunded_cash) AS total_refunds,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
    FROM base
    JOIN date_dim dd ON base.ss_sold_date_sk = dd.d_date_sk
    JOIN store s ON base.s_store_id = s.s_store_id
    JOIN warehouse w ON base.w_warehouse_id = w.w_warehouse_id
    JOIN store_sales ss ON base.ss_ticket_number = ss.ss_ticket_number
    JOIN store_returns sr ON base.ss_ticket_number = sr.sr_ticket_number
    JOIN web_sales ws ON base.ss_ticket_number = ws.ws_order_number
    GROUP BY CUBE (dd.d_year, s.s_state, w.w_state, s.s_store_id)
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    agg.d_year,
    agg.store_state,
    agg.warehouse_state,
    agg.s_store_id,
    agg.store_sales_amount,
    agg.web_sales_amount,
    agg.total_refunds,
    agg.num_tickets,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.store_sales_amount DESC) AS sales_rank
FROM agg
WHERE agg.s_store_id NOT IN (
    SELECT s_store_id FROM store WHERE s_number_employees > 1000
)
ORDER BY agg.d_year, sales_rank
LIMIT 100
