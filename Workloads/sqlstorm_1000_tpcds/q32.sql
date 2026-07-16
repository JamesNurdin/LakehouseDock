WITH
catalog_sales_agg AS (
    SELECT
        d.d_year,
        cc.cc_state AS state,
        i.i_category,
        cs.cs_order_number AS order_key,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_discount_amt) AS discount_amount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, cc.cc_state, i.i_category, cs.cs_order_number
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        cc.cc_state AS state,
        i.i_category,
        cr.cr_order_number AS order_key,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, cc.cc_state, i.i_category, cr.cr_order_number
),
web_sales_agg AS (
    SELECT
        d.d_year,
        ca.ca_state AS state,
        i.i_category,
        ws.ws_order_number AS order_key,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_discount_amt) AS discount_amount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category, ws.ws_order_number
),
web_returns_agg AS (
    SELECT
        d.d_year,
        ca.ca_state AS state,
        i.i_category,
        wr.wr_order_number AS order_key,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category, wr.wr_order_number
),
store_sales_agg AS (
    SELECT
        d.d_year,
        s.s_state AS state,
        i.i_category,
        ss.ss_ticket_number AS order_key,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_discount_amt) AS discount_amount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category, ss.ss_ticket_number
),
store_returns_agg AS (
    SELECT
        d.d_year,
        s.s_state AS state,
        i.i_category,
        sr.sr_ticket_number AS order_key,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category, sr.sr_ticket_number
),
combined_sales AS (
    SELECT d_year, state, i_category, channel, order_key,
        net_profit,
        discount_amount,
        distinct_customers,
        total_quantity
    FROM (
        SELECT d_year, state, i_category, 'Catalog' AS channel, order_key,
            net_profit, discount_amount, distinct_customers, total_quantity
        FROM catalog_sales_agg
        UNION ALL
        SELECT d_year, state, i_category, 'Web' AS channel, order_key,
            net_profit, discount_amount, distinct_customers, total_quantity
        FROM web_sales_agg
        UNION ALL
        SELECT d_year, state, i_category, 'Store' AS channel, order_key,
            net_profit, discount_amount, distinct_customers, total_quantity
        FROM store_sales_agg
    ) u
),
combined_returns AS (
    SELECT d_year, state, i_category, channel, order_key,
        net_loss,
        return_quantity
    FROM (
        SELECT d_year, state, i_category, 'Catalog' AS channel, order_key,
            net_loss, return_quantity
        FROM catalog_returns_agg
        UNION ALL
        SELECT d_year, state, i_category, 'Web' AS channel, order_key,
            net_loss, return_quantity
        FROM web_returns_agg
        UNION ALL
        SELECT d_year, state, i_category, 'Store' AS channel, order_key,
            net_loss, return_quantity
        FROM store_returns_agg
    ) u
),
final_agg AS (
    SELECT
        cs.d_year,
        cs.state,
        cs.i_category,
        cs.channel,
        SUM(cs.net_profit) AS total_profit,
        COALESCE(SUM(cr.net_loss), 0) AS total_loss,
        SUM(cs.net_profit) - COALESCE(SUM(cr.net_loss), 0) AS net_profit_after_returns,
        SUM(cs.discount_amount) AS total_discount,
        SUM(cs.total_quantity) AS total_quantity_sold,
        COALESCE(SUM(cr.return_quantity), 0) AS total_quantity_returned,
        SUM(cs.distinct_customers) AS total_distinct_customers
    FROM combined_sales cs
    LEFT JOIN combined_returns cr
        ON cs.d_year = cr.d_year
        AND cs.state = cr.state
        AND cs.i_category = cr.i_category
        AND cs.channel = cr.channel
        AND cs.order_key = cr.order_key
    GROUP BY cs.d_year, cs.state, cs.i_category, cs.channel
)
SELECT
    d_year,
    state,
    i_category,
    channel,
    total_profit,
    total_loss,
    net_profit_after_returns,
    total_discount,
    total_quantity_sold,
    total_quantity_returned,
    total_distinct_customers,
    RANK() OVER (PARTITION BY d_year ORDER BY net_profit_after_returns DESC) AS profit_rank,
    SUM(net_profit_after_returns) OVER (PARTITION BY state ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_state
FROM final_agg
WHERE d_year BETWEEN 2001 AND 2002
ORDER BY d_year, net_profit_after_returns DESC
