WITH joined_data AS (
    SELECT
        s.s_store_name,
        p_ss.p_promo_name,
        cd_ss.cd_gender,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM store_sales ss
    INNER JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    INNER JOIN item i_ss
        ON ss.ss_item_sk = i_ss.i_item_sk
    INNER JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    INNER JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    INNER JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    -- store returns related to the same sale
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    INNER JOIN time_dim t_ret
        ON sr.sr_return_time_sk = t_ret.t_time_sk
    -- catalog sales linked through the shared item
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i_ss.i_item_sk
    INNER JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    -- catalog returns linked to catalog sales via order number and item
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i_ss.i_item_sk
    INNER JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    -- ship mode (used by both catalog sales and returns)
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    -- warehouse (used by catalog sales, returns, and inventory)
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- inventory for the same item and warehouse
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i_ss.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- web returns for the same item
    INNER JOIN web_returns wr
        ON wr.wr_item_sk = i_ss.i_item_sk
    INNER JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    -- second promotion alias for catalog sales (optional, shows reuse)
    INNER JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    GROUP BY
        s.s_store_name,
        p_ss.p_promo_name,
        cd_ss.cd_gender
    HAVING
        SUM(ss.ss_net_profit) > 1000
)
SELECT
    jd.s_store_name,
    jd.p_promo_name,
    jd.cd_gender,
    jd.total_store_profit,
    jd.total_catalog_sales,
    jd.order_count,
    RANK() OVER (ORDER BY jd.total_store_profit DESC) AS profit_rank
FROM joined_data jd
ORDER BY profit_rank
LIMIT 100
