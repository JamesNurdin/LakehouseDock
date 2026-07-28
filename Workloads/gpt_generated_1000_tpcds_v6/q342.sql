WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        td.t_shift,
        td.t_sub_shift,
        ca.ca_state,
        cd.cd_gender,
        MAX(inv.inv_quantity_on_hand) AS max_qty_on_hand,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS return_loss,
        SUM(ss.ss_quantity + cs.cs_quantity) AS total_qty,
        CASE
            WHEN SUM(ss.ss_net_profit + cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) > 5000 THEN 'High'
            ELSE 'Low'
        END AS profit_segment
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE
        p.p_channel_catalog = 'N'                     -- predicate 1
        AND inv.inv_quantity_on_hand > 0            -- predicate 2
        AND td.t_shift IN ('first', 'second')       -- predicate 3
        AND td.t_sub_shift = 'morning'              -- predicate 4
        AND ca.ca_state = 'CA'                      -- predicate 5
        AND cd.cd_gender = 'M'                      -- predicate 6
        AND i.i_item_desc LIKE '%Bike%'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        td.t_shift,
        td.t_sub_shift,
        ca.ca_state,
        cd.cd_gender
)
SELECT
    i_item_id,
    i_item_desc,
    profit_segment,
    total_qty,
    store_profit,
    catalog_profit,
    return_loss,
    ROW_NUMBER() OVER (ORDER BY (store_profit + catalog_profit - return_loss) DESC) AS profit_rank,
    CASE
        WHEN profit_segment = 'High' AND t_shift = 'first' THEN 'PremiumFirst'
        ELSE 'Standard'
    END AS segment_label
FROM sales_agg
WHERE
    max_qty_on_hand > 0               -- additional filter (predicate 7)
ORDER BY profit_rank
LIMIT 100
