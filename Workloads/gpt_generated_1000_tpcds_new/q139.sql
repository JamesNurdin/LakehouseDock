WITH base AS (
    SELECT
        ss.*, 
        d.*, 
        t.*, 
        i.*, 
        cd.*, 
        hd.*, 
        ca.*, 
        s.*, 
        sr.*, 
        r.*, 
        cs.*, 
        cp.*, 
        sm.*, 
        ws.*, 
        we.*, 
        wr.*
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND we.web_name LIKE '%Online%'
)
SELECT
    base.d_date,
    base.s_store_name,
    base.i_item_id,
    base.ss_quantity,
    base.ws_quantity,
    base.ss_net_profit,
    base.ws_net_profit,
    (base.ss_net_profit + base.ws_net_profit) AS total_profit,
    RANK() OVER (PARTITION BY base.d_year ORDER BY (base.ss_net_profit + base.ws_net_profit) DESC) AS profit_rank,
    base.r_reason_desc
FROM base
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr_check
    WHERE sr_check.sr_store_sk = base.s_store_sk
      AND sr_check.sr_return_quantity > 0
)
ORDER BY total_profit DESC, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
