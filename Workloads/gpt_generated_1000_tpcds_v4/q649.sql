WITH joined_data AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ss.ss_quantity,
        i.i_current_price,
        ss.ss_net_profit,
        COALESCE(sr.sr_net_loss, 0) AS sr_net_loss,
        COALESCE(cr.cr_net_loss, 0) AS cr_net_loss,
        COALESCE(wr.wr_net_loss, 0) AS wr_net_loss,
        sm.sm_carrier
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON ss.ss_item_sk = wr.wr_item_sk
    WHERE ss.ss_quantity > 2
      AND i.i_current_price > 20
      AND sm.sm_carrier = 'FEDEX'
      AND s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451915 AND 2451925
),
aggregated AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_profit) AS total_sales_profit,
        SUM(sr_net_loss) AS total_store_returns_loss,
        SUM(cr_net_loss) AS total_catalog_returns_loss,
        SUM(wr_net_loss) AS total_web_returns_loss,
        (SUM(ss_net_profit) - SUM(sr_net_loss) - SUM(cr_net_loss) - SUM(wr_net_loss)) AS net_profit_after_returns
    FROM joined_data
    GROUP BY s_store_id, s_store_name, s_state
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    total_quantity_sold,
    total_sales_profit,
    total_store_returns_loss,
    total_catalog_returns_loss,
    total_web_returns_loss,
    net_profit_after_returns,
    ROW_NUMBER() OVER (ORDER BY net_profit_after_returns DESC) AS store_rank
FROM aggregated
ORDER BY store_rank
LIMIT 100
