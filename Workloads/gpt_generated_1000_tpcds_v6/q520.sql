WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_city,
        td.t_hour,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cr.cr_net_loss) AS return_loss,
        SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_total
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_hour BETWEEN 9 AND 17
        AND cc.cc_city = 'Ash Hill'
        AND cs.cs_promo_sk IN (462, 1171)
    GROUP BY cc.cc_call_center_id, cc.cc_city, td.t_hour
    HAVING SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) > 5000
)
SELECT
    a.cc_call_center_id,
    a.cc_city,
    a.t_hour,
    a.catalog_profit,
    a.return_loss,
    a.net_total,
    CASE WHEN a.net_total > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    CASE WHEN a.net_total > (SELECT AVG(net_total) FROM agg) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS relative_to_avg,
    ROW_NUMBER() OVER (PARTITION BY a.cc_call_center_id ORDER BY a.net_total DESC) AS rank_within_center
FROM agg a
ORDER BY a.net_total DESC, a.cc_call_center_id
LIMIT 100
