WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_year AS d_year,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM store s
    -- Store Returns side
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN customer_demographics cd_ret
        ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret
        ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    -- Web Sales side (joined through already‑available dimensions)
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd_ret.cd_demo_sk
    JOIN date_dim d_sales
        ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ws.ws_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    -- Promotion date joins (second and third aliases of date_dim)
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    -- Inventory and income band joins
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d_sales.d_date_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sales.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d_sales.d_year
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    sa.s_store_sk,
    sa.s_store_name,
    sa.d_year,
    sa.total_web_profit,
    sa.total_store_loss,
    sa.web_orders,
    sa.return_tickets,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_name ORDER BY sa.total_web_profit DESC) AS rn
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    WHERE sr2.sr_store_sk = sa.s_store_sk
      AND r2.r_reason_desc = 'Defective'
)
ORDER BY sa.total_web_profit DESC
LIMIT 100
