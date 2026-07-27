WITH base AS (
    SELECT
        s.s_store_sk AS s_store_sk,
        s.s_market_manager AS s_market_manager,
        i.i_manufact AS i_manufact,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit + ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        AVG(p.p_cost) AS avg_catalog_promo_cost,
        AVG(p2.p_cost) AS avg_store_promo_cost,
        AVG(pa.avg_promo_cost) AS avg_item_promo_cost
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p2
        ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN (
        SELECT p_item_sk, AVG(p_cost) AS avg_promo_cost
        FROM promotion
        GROUP BY p_item_sk
    ) pa
        ON i.i_item_sk = pa.p_item_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY s.s_store_sk, s.s_market_manager, i.i_manufact
)
SELECT
    s_store_sk,
    s_market_manager,
    i_manufact,
    catalog_profit,
    store_profit,
    total_profit,
    catalog_orders,
    store_tickets,
    avg_catalog_promo_cost,
    avg_store_promo_cost,
    avg_item_promo_cost,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY total_profit DESC
LIMIT 100
